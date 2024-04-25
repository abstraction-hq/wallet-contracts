// SPDX-License-Identifier: Apache
pragma solidity ^0.8.0;

import "./interfaces/IWallet.sol";

import "@account-abstraction/contracts/core/BaseAccount.sol";
import "@account-abstraction/contracts/interfaces/IEntryPoint.sol";

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/interfaces/IERC1271.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

import "./interfaces/IWallet.sol";
import "./interfaces/IKey.sol";

import "./libraries/WalletStorage.sol";
import "./libraries/DefaultCallbackHandler.sol";

import "./KeyStore.sol";

/**
 * @title Ziphius Wallet on Ethereum network
 * @author Terry
 * @notice Ziphius wallet
 */
contract EthereumWallet is IWallet, BaseAccount, Initializable, DefaultCallbackHandler, IERC1271 {
    IEntryPoint private immutable _entryPoint;

    using Address for address;
    using ECDSA for bytes32;

    constructor(address entryPoint_) {
        _entryPoint = IEntryPoint(entryPoint_);
    }

    function init(address keyStore) external virtual initializer {
        WalletStorage.setKeyStore(keyStore);
    }

    modifier authorized() {
        require(_isValidCaller(), "Ziphius: Invalid Caller");
        _;
    }

    /**
     * validate userOp
     */
    function _validateSignature(
        UserOperation calldata userOp,
        bytes32 userOpHash
    ) internal override returns (uint256 validationData) {
        address key = address(bytes20(userOp.signature[:20]));
        bytes memory signature = userOp.signature[20:];

        IKeyStore keyStore = IKeyStore(WalletStorage.getKeyStore());

        if (keyStore.isValidKey(key)) {
            if (key.isContract()) {
                validationData = IKey(key).validateUserOp(userOp, userOpHash);
            } else {
                bytes32 hash = userOpHash.toEthSignedMessageHash();
                if (key == hash.recover(signature)) {
                    validationData = 0;
                } else {
                    validationData = SIG_VALIDATION_FAILED;
                }
            }
        } else {
            validationData = SIG_VALIDATION_FAILED;
        }
    }


    /**
     * @notice only accept entrypoint
     */
    function _isValidCaller() internal view returns (bool) {
        return msg.sender == address(entryPoint());
    }

    /**
     * execute a transactions
     */
    function _call(address target, uint256 value, bytes memory data) internal {
        require(target != WalletStorage.getKeyStore(), "Ziphius: Don't trigger keystore");
        (bool success, bytes memory result) = target.call{ value: value }(data);
        if (!success) {
            assembly {
                revert(add(result, 32), mload(result))
            }
        }
    }

    /// @inheritdoc IWallet
    function execute(address dest, uint256 value, bytes calldata func) external override(IWallet) authorized {
        _call(dest, value, func);
        emit Execute();
    }

    /// @inheritdoc IWallet
    function executeBatch(address[] calldata dest, uint256[] calldata values, bytes[] calldata func) external override(IWallet) authorized {
        require(dest.length == func.length, "Ziphius: Wrong array lengths");
        for (uint256 i = 0; i < dest.length; i++) {
            _call(dest[i], values[i], func[i]);
        }
        emit Execute();
    }

    function addKey(address key, uint256 walletIndex) external authorized {
        IKeyStore keyStore = IKeyStore(WalletStorage.getKeyStore());
        keyStore.addKey(key, walletIndex);
    }

    function removeKey(address prevKey, address key, uint256 walletIndex) external authorized {
        IKeyStore keyStore = IKeyStore(WalletStorage.getKeyStore());
        keyStore.removeKey(prevKey, key, walletIndex);
    }

    function entryPoint() public view override returns (IEntryPoint) {
        return _entryPoint;
    }

    /**
     * validate signature base on IERC1271
     */
    function isValidSignature(bytes32 hash, bytes calldata signature) public view override returns (bytes4 magicValue) {
        address key = address(bytes20(signature[:20]));
        bytes memory trueSignature = signature[20:];

        IKeyStore keyStore = IKeyStore(WalletStorage.getKeyStore());

        if (keyStore.isValidKey(key)) {
            if (key.isContract()) {
                magicValue = IKey(key).isValidSignature(hash, trueSignature);
            } else {
                if (key == hash.recover(trueSignature)) {
                    magicValue = this.isValidSignature.selector;
                } else {
                    magicValue = bytes4(0xffffffff);
                }
            }
        } else {
            magicValue = bytes4(0xffffffff);
        }
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(DefaultCallbackHandler) returns (bool) {
        return interfaceId == type(IWallet).interfaceId
            || interfaceId == type(IERC1271).interfaceId
            || super.supportsInterface(interfaceId);
    }
}