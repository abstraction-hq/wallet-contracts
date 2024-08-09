// SPDX-License-Identifier: Apache
pragma solidity ^0.8.0;

import "account-abstraction/core/BaseAccount.sol";
import "openzeppelin/proxy/utils/Initializable.sol";
import "openzeppelin/utils/cryptography/ECDSA.sol";
import "openzeppelin/utils/StorageSlot.sol";
import "openzeppelin/proxy/utils/UUPSUpgradeable.sol";
import "openzeppelin/interfaces/IERC1271.sol";

import "./interfaces/IModule.sol";
import "./interfaces/IKeyStore.sol";
import "./interfaces/IWallet.sol";
import "./libraries/DefaultCallbackHandler.sol";

/**
 * @title Wallet
 * @notice This contract represents a Wallet in the system.
 */
contract Wallet is IWallet, IERC1271, BaseAccount, Initializable, DefaultCallbackHandler, UUPSUpgradeable {
    using ECDSA for bytes32;
    using Address for address;

    address public immutable SENTINEL_ADDRESS = address(0x1);
    bytes32 public immutable KEY_STORE_SLOT = bytes32(uint256(keccak256("key-store")) - 1);
    bytes32 public immutable WALLET_INDEX_SLOT = bytes32(uint256(keccak256("wallet-index")) - 1);

    IEntryPoint private immutable _entryPoint;

    struct CallbackModule {
        UserOperation userOp;
        address module;
        bytes32 userOpHash;
    }

    CallbackModule private _callbackCache;

    constructor(address entryPointAddress ) {
        _entryPoint = IEntryPoint(entryPointAddress);
    }

    modifier moduleCallback() {
        _;
        _moduleCallback();
    }

    modifier authorized() {
        require(_isValidCaller(), "Wallet: Invalid Caller");
        _;
    }

    function _authorizeUpgrade(address) internal override authorized {}

    function _moduleCallback() internal {
        if (_callbackCache.module != address(0)) {
            IModule(_callbackCache.module).callback(_callbackCache.userOp, _callbackCache.userOpHash);
            delete _callbackCache;
        }
    }

    function _validateSignature(UserOperation calldata userOp, bytes32 userOpHash)
        internal
        override
        returns (uint256 validationData)
    {
        return IKeyStore(getKeyStore()).validateUserOp(getWalletIndex(), userOp, userOpHash);
    }

    /**
     * @notice only accept entrypoint or self call
     */
    function _isValidCaller() internal view returns (bool) {
        return msg.sender == address(entryPoint()) || msg.sender == address(this);
    }

    /**
     * execute a transactions
     */
    function _call(address target, uint256 value, bytes memory data) internal {
        (bool success, bytes memory result) = target.call{value: value}(data);
        if (!success) {
            assembly {
                revert(add(result, 32), mload(result))
            }
        }
    }

    /// @inheritdoc IWallet
    function execute(address dest, uint256 value, bytes calldata func)
        external
        override(IWallet)
        authorized
        moduleCallback
    {
        _call(dest, value, func);
        emit Execute();
    }

    /// @inheritdoc IWallet
    function executeBatch(address[] calldata dest, uint256[] calldata values, bytes[] calldata func)
        external
        override(IWallet)
        authorized
        moduleCallback
    {
        require(dest.length == func.length, "Wrong array lengths");
        for (uint256 i = 0; i < dest.length; i++) {
            _call(dest[i], values[i], func[i]);
        }
        emit Execute();
    }

    function entryPoint() public view override returns (IEntryPoint) {
        return _entryPoint;
    }

    /**
     * validate signature base on IERC1271
     */
    function isValidSignature(bytes32 hash, bytes calldata signature)
        public
        view
        override
        returns (bytes4 magicValue)
    {
        return IKeyStore(getKeyStore()).isValidSignature(hash, signature);
    }

    function getWalletIndex() public view returns (uint256) {
        return StorageSlot.getUint256Slot(WALLET_INDEX_SLOT).value;
    }

    function getKeyStore() public view returns (address) {
        return StorageSlot.getAddressSlot(KEY_STORE_SLOT).value;
    }
}
