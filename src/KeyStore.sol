// SPDX-License-Identifier: Apache
pragma solidity ^0.8.0;

import "account-abstraction/interfaces/UserOperation.sol";
import "openzeppelin/proxy/utils/Initializable.sol";
import "openzeppelin/utils/Create2.sol";
import "openzeppelin/interfaces/IERC1271.sol";

import "./interfaces/IWalletFactory.sol";
import "./interfaces/IModule.sol";
import "./interfaces/IKeyStore.sol";
import "./interfaces/IVerifier.sol";
import "./libraries/CustomERC1967.sol";

contract KeyStore is IKeyStore {
    uint256 constant internal SIG_VALIDATION_FAILED = 1;

    address public immutable factory;
    bytes32 public immutable ANCHOR_KEY = keccak256("ANCHOR_KEY");

    mapping(uint8 => address) private _verifiers;
    mapping(address => bool) private _modules;
    
    // Keys details
    mapping(bytes32 => bytes32) private _keyLists;
    mapping(bytes32 => bytes) private _keys;

    uint256 private _totalKey;
    bytes[] private _keyList;

    event SetVerifier(uint8 indexed keyType, address verifier);
    event AddKey(bytes32 indexed keyIndex, bytes value);
    event RemoveKey(bytes32 indexed keyIndex);
    event SetModule(address indexed module, bool status);

    constructor(uint8[] memory keyTypes, address[] memory verifiers, bytes memory initKey) {
        factory = msg.sender;
        for (uint256 i = 0; i < keyTypes.length; i++) {
            _verifiers[keyTypes[i]] = verifiers[i];
        }

        (bytes32 keyIndex, bytes memory value) = abi.decode(initKey, (bytes32, bytes));
        _keyLists[ANCHOR_KEY] = keyIndex;
        _keyLists[keyIndex] = ANCHOR_KEY;
        _keys[keyIndex] = value;

        _totalKey = 1;
    }

    modifier onlyWallet(uint256 walletIndex) {
        require(IWalletFactory(factory).calculateWalletAddress(address(this), walletIndex) == msg.sender, "KeyStore: caller is not a module");
        _;
    }

    modifier onlyWalletOrModule(uint256 walletIndex) {
        require(IWalletFactory(factory).calculateWalletAddress(address(this), walletIndex) == msg.sender, "KeyStore: caller is not a module");
        _;
    }

    function _addKey(bytes memory key) internal {
        (bytes32 keyIndex, bytes memory value) = abi.decode(key, (bytes32, bytes));
        require(keyIndex != bytes32(0) && keyIndex != ANCHOR_KEY, "KeyStore: key index is empty");

        _keyLists[keyIndex] = _keyLists[ANCHOR_KEY];
        _keyLists[ANCHOR_KEY] = keyIndex;

        _totalKey += 1;
        _keys[keyIndex] = value;

        emit AddKey(keyIndex, value);
    }

    function _removeKey(bytes32 prevKey, bytes32 key) internal {
        require(_totalKey > 1, "KeyStore: Cannot remove the last key");
        require(key != bytes32(0) && key != ANCHOR_KEY, "KeyStore: Invalid Key");
        require(_keyLists[prevKey] == key, "KeyStore: Invalid prevKey");

        _keyLists[prevKey] = _keyLists[key];
        _keyLists[key] = bytes32(0);

        _totalKey -= 1;
        delete _keys[key];

        emit RemoveKey(key);
    }

    function setVerifier(uint256 walletIndex, uint8 keyType, address verifier) public onlyWallet(walletIndex) {
        _verifiers[keyType] = verifier;

        emit SetVerifier(keyType, verifier);
    }

    /**
     * @dev Add the key to the key store
     * @param walletIndex the wallet index
     * @param key key to be added
     */
    function addKey(uint256 walletIndex, bytes calldata key) public onlyWallet(walletIndex) {
        _addKey(key);
    }

    /**
     * @dev Remove the key from the key store
     * @param walletIndex the wallet index
     * @param prevKey which is the previous key
     * @param key key to be removed
     */
    function removeKey(uint256 walletIndex, bytes32 prevKey, bytes32 key) public onlyWallet(walletIndex) {
        _removeKey(prevKey, key);
    }

    /**
     * @dev Set the module status
     * @param walletIndex wallet index
     * @param module the module address
     * @param status the status of the module
     */
    function setModule(uint256 walletIndex, address module, bool status) public onlyWallet(walletIndex) {
        _modules[module] = status;
        emit SetModule(module, status);
    }

    /**
     * @dev Validate the user operation
     * @param userOp user operation
     * @param userOpHash User Op hash
     */
    function validateUserOp(uint256 walletIndex, UserOperation calldata userOp, bytes32 userOpHash) external override onlyWallet(walletIndex) returns(uint256) {
        address module = address(bytes20(userOp.signature[:20]));

        // if the module is a valid module, then use the module to validate the userOp
        if (isValidModule(module)) {
            return IModule(module).validateUserOp(userOp, userOpHash);
        }

        // Using the KeyStore to validate the signature
        if (isValidSignature(userOpHash, userOp.signature) == this.isValidSignature.selector) {
            return 0;
        }

        return SIG_VALIDATION_FAILED;
    }

    /**
     * @dev Validate the signature
     * @param hash the hash to be signed
     * @param signature the signature
     */
    function isValidSignature(bytes32 hash, bytes calldata signature) public view override returns (bytes4) {
        // Validate signature
        (bytes32 keyIndex, bytes memory decodedSignature) = abi.decode(signature, (bytes32, bytes));
        (uint8 keyType, bytes memory publicKey) = abi.decode(_keys[keyIndex], (uint8, bytes));
        address verifier = _verifiers[keyType];
        require(verifier != address(0), "KeyStore: Invalid verifier");

        // Using the verifier to validate the signature
        if (IVerifier(verifier).verify(hash, publicKey, decodedSignature)) {
            return this.isValidSignature.selector;
        }

        return 0x00000000;
    }

    function getKeys() public view returns (bytes[] memory) {
        bytes[] memory keyValues = new bytes[](_totalKey);

        bytes32 keyIndex = _keyLists[ANCHOR_KEY];
        for (uint256 i = 0; i < _totalKey; i++) {
            keyValues[i] = _keys[keyIndex];
            keyIndex = _keyLists[keyIndex];
        }

        return keyValues;
    }
    
    function getTotalKey() public view returns (uint256) {
        return _totalKey;
    }

    function getVerifier(uint8 keyType) public view returns (address) {
        return _verifiers[keyType];
    }

    function isValidModule(address module) public view returns (bool) {
        return _modules[module];
    }
}