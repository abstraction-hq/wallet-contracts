// SPDX-License-Identifier: Apache
pragma solidity ^0.8.0;

import "account-abstraction/core/BaseAccount.sol";
import "openzeppelin/proxy/utils/Initializable.sol";
import "openzeppelin/utils/cryptography/ECDSA.sol";
import "openzeppelin/utils/StorageSlot.sol";
import "openzeppelin/proxy/utils/UUPSUpgradeable.sol";
import "openzeppelin/interfaces/IERC1271.sol";

import "./interfaces/IModule.sol";
import "./interfaces/IWallet.sol";
import "./libraries/DefaultCallbackHandler.sol";

/**
 * @title Wallet
 * @author imduchuyyy
 * @notice This contract represents a Wallet in the system.
 */
contract Wallet is IWallet, IERC1271, BaseAccount, Initializable, DefaultCallbackHandler, UUPSUpgradeable {
    using ECDSA for bytes32;
    using Address for address;

    address public immutable SENTINEL_ADDRESS = address(0x1);
    bytes32 public immutable KEY_MANAGE_PREFIX_SLOT = bytes32(uint256(keccak256("contract.v1.key-manage")) - 1);
    bytes32 public immutable KEY_COUNT_SLOT = bytes32(uint256(keccak256("contract.v1.key-count")) - 1);

    IEntryPoint private immutable _entryPoint;

    struct CallbackModule {
        UserOperation userOp;
        address module;
        bytes32 userOpHash;
    }

    CallbackModule private _callbackCache;

    constructor(address entryPointAddress) {
        _entryPoint = IEntryPoint(entryPointAddress);
    }

    /**
     * @notice This function is used to initialize the wallet with an initial key.
     */
    function __Wallet_init(bytes memory initData) external initializer {
        (address bootstrap, bytes memory callData) = abi.decode(initData, (address, bytes));
        (bool success,) = bootstrap.delegatecall(callData);
        if (!success) revert("Wallet: Bootstrap failed");
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

    function _setKey(address key, address value) internal {
        bytes32 slotKey = keccak256(abi.encode(KEY_MANAGE_PREFIX_SLOT, key));
        StorageSlot.getAddressSlot(slotKey).value = value;
    }

    function _getKey(address key) internal view returns (address) {
        bytes32 slotKey = keccak256(abi.encode(KEY_MANAGE_PREFIX_SLOT, key));
        return StorageSlot.getAddressSlot(slotKey).value;
    }

    function _increaseTotalKey() internal {
        StorageSlot.getUint256Slot(KEY_COUNT_SLOT).value++;
    }

    function _decreaseTotalKey() internal {
        StorageSlot.getUint256Slot(KEY_COUNT_SLOT).value--;
    }

    function _getTotalKey() internal view returns (uint256) {
        return StorageSlot.getUint256Slot(KEY_COUNT_SLOT).value;
    }

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
        address key = address(bytes20(userOp.signature[:20]));
        bytes memory trueSignature = userOp.signature[20:];

        if (isValidKey(key)) {
            if (key.isContract()) {
                _callbackCache = CallbackModule(userOp, key, userOpHash);
                validationData = IModule(key).validateUserOp(userOp, userOpHash);
            } else {
                bytes32 hash = userOpHash.toEthSignedMessageHash();
                if (key == hash.recover(trueSignature)) {
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

    function addKey(address key) external override authorized moduleCallback {
        require(key != address(0) && key != SENTINEL_ADDRESS && key != address(this), "Invalid Key");
        address firstKey = _getKey(SENTINEL_ADDRESS);
        _setKey(key, firstKey);
        _setKey(SENTINEL_ADDRESS, key);

        _increaseTotalKey();
    }

    function removeKey(address prevKey, address key) external override authorized moduleCallback {
        require(key != address(0) && key != SENTINEL_ADDRESS, "Invalid Key");
        require(_getKey(prevKey) == key, "Invalid prevKey");

        _setKey(prevKey, _getKey(key));
        _setKey(key, address(0));

        _decreaseTotalKey();
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
        address key = address(bytes20(signature[:20]));
        bytes memory trueSignature = signature[20:];

        if (isValidKey(key)) {
            if (key.isContract()) {
                magicValue = IModule(key).isValidSignature(hash, trueSignature);
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

    function isValidKey(address key) public view returns (bool) {
        return _getKey(key) != address(0) && key != SENTINEL_ADDRESS;
    }

    function getTotalKey() public view returns (uint256) {
        return _getTotalKey();
    }

    /**
     * @notice This function is used to get the current keys of the wallet.
     * @return keys The current keys of the wallet.
     */
    function getKeys() external view returns (address[] memory keys) {
        uint256 totalKey = getTotalKey();
        address[] memory array = new address[](totalKey);

        // populate return array
        uint256 index = 0;
        address currentKey = _getKey(SENTINEL_ADDRESS);
        while (currentKey != SENTINEL_ADDRESS) {
            array[index] = currentKey;
            currentKey = _getKey(currentKey);
            index++;
        }
        return array;
    }
}
