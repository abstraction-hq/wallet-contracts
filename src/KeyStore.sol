// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "account-abstraction/core/BaseAccount.sol";
import "account-abstraction/interfaces/IEntryPoint.sol";
import "openzeppelin/proxy/utils/UUPSUpgradeable.sol";
import "openzeppelin/utils/Create2.sol";
import "openzeppelin/proxy/utils/Initializable.sol";

import "./libraries/WalletProxy.sol";

import "./interfaces/IKeyStore.sol";

/**
 * @title Ziphius Keystore
 * @author Terry
 * @notice Ziphius Keystore, this smart contract will be deploy to Ethereum only
 */
contract KeyStore is IKeyStore, Initializable {
    address public immutable factory;
    address public immutable SENTINAL_ADDRESS = address(0x1);
    bytes32 public immutable WALLET_BYTE_CODE_HASH = keccak256(abi.encodePacked(
        type(WalletProxy).creationCode,
        ""
    ));

    mapping(address => address) private _keys;
    uint256 internal _keyCount;

    event SetKey(address key, bool isActives);

    constructor() {
        factory = msg.sender;
    }

    function init(address initKey) external override initializer {
        _keys[SENTINAL_ADDRESS] = initKey;
        _keys[initKey] = SENTINAL_ADDRESS;

        _keyCount++;
    }

    /**
     * @notice only accept wallet
     */
    function _requireFromWallet(uint256 walletIndex) internal view {
        bytes32 salt = keccak256(abi.encode(address(this), walletIndex));
        address wallet = Create2.computeAddress(salt, WALLET_BYTE_CODE_HASH, factory);

        require(wallet == msg.sender, "KeyStore: Caller is not wallet");
    }

    function _addKey(address key) internal {
        require(key != address(0) && key != SENTINAL_ADDRESS && key != address(this), "KeyStore: Invalid Key");
        _keys[key] = _keys[SENTINAL_ADDRESS];
        _keys[SENTINAL_ADDRESS] = key;
        _keyCount++;
    }

    function _removeKey(address prevKey, address key) internal {
        require(key != address(0) && key != SENTINAL_ADDRESS, "KeyStore: Invalid Key");
        require(_keys[prevKey] == key, "KeyStore: Invalid prevKey");
        _keys[prevKey] = _keys[key];
        _keys[key] = address(0);
        _keyCount--;
    }

    function addKey(address key, uint256 walletIndex) external override {
        _requireFromWallet(walletIndex);
        _addKey(key);

        emit SetKey(key, true);
    }

    function removeKey(address prevKey, address key, uint256 walletIndex) external override {
        _requireFromWallet(walletIndex);
        _removeKey(prevKey, key);

        emit SetKey(key, false);
    }

    function getKeys() external view override returns (address[] memory keys) {
        address[] memory array = new address[](_keyCount);

        // populate return array
        uint256 index = 0;
        address currentKey = _keys[SENTINAL_ADDRESS];
        while (currentKey != SENTINAL_ADDRESS) {
            array[index] = currentKey;
            currentKey = _keys[currentKey];
            index++;
        }
        return array;
    }

    function isValidKey(address key) external view override returns (bool) {
        return _keys[key] != address(0) && key != SENTINAL_ADDRESS;
    }
}