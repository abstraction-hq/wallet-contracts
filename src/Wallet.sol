// SPDX-License-Identifier: Apache
pragma solidity ^0.8.0;

import "account-abstraction/core/BaseAccount.sol";
import "openzeppelin/proxy/utils/Initializable.sol";
import "openzeppelin/utils/cryptography/ECDSA.sol";

import "./interfaces/IKeyStore.sol";
import "./interfaces/IWallet.sol";
import "./libraries/WalletStorage.sol";

contract Wallet is IWallet, BaseAccount, Initializable {
    using ECDSA for bytes32;
    IEntryPoint private immutable _entryPoint;

    constructor(address entryPointAddress) {
        _entryPoint = IEntryPoint(entryPointAddress);
    }

    modifier authorized() {
        require(_isValidCaller(), "Wallet: Invalid Caller");
        _;
    }

    function __Wallet_init(address keystore, address factory) external initializer {
        WalletStorage.setAddress(WalletStorage.KEYSTORE_POSITION, keystore);
        WalletStorage.setAddress(WalletStorage.FACTORY_POSITION, factory);
    }

    function entryPoint() public view override returns (IEntryPoint) {
        return _entryPoint;
    }

    function _validateSignature(UserOperation calldata userOp, bytes32 userOpHash)
        internal
        view
        override
        returns (uint256 validationData)
    {
        bytes32 digest = userOpHash.toEthSignedMessageHash();
        IKeyStore keyStore = IKeyStore(WalletStorage.getAddress(WalletStorage.KEYSTORE_POSITION));
        if (keyStore.isValidKey(digest.recover(userOp.signature))) {
            validationData = 0;
        } else {
            validationData = SIG_VALIDATION_FAILED;
        }

        return 1;
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
        (bool success, bytes memory result) = target.call{ value: value }(data);
        if (!success) {
            assembly {
                revert(add(result, 32), mload(result))
            }
        }
    }

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
}
