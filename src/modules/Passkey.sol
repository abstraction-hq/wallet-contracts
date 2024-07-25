// SPDX-License-Identifier: Apache
pragma solidity ^0.8.0;

import "openzeppelin/utils/Create2.sol";

import "../interfaces/IModule.sol";
import "../interfaces/IWallet.sol";
import "../libraries/Base64Url.sol";

import {WebAuthn} from "../libraries/WebAuthn.sol";

contract PasskeyModule is IModule {
    struct PublicKey {
        uint256 x;
        uint256 y;
    }

    mapping(address => mapping(bytes32 => PublicKey)) private _publicKeys;
    mapping(bytes32 => address) private _wallets;

    event PasskeyRegistered(address indexed user, bytes32 indexed keyId, uint256 x, uint256 y);
    event PasskeyRemoved(address indexed user, bytes32 indexed keyId);

    function registerPublicKey(bytes32 keyId, uint256 x, uint256 y) external {
        require(_wallets[keyId] == address(0), "PasskeyModule: keyId already registered");

        _publicKeys[msg.sender][keyId] = PublicKey(x, y);
        _wallets[keyId] = msg.sender;

        emit PasskeyRegistered(msg.sender, keyId, x, y);
    }

    function removePublicKey(bytes32 keyId) external {
        require(_wallets[keyId] == msg.sender, "PasskeyModule: Unauthorized");
        delete _publicKeys[msg.sender][keyId];
        delete _wallets[keyId];

        emit PasskeyRemoved(msg.sender, keyId);
    }

    function _validatePasskeySignature(bytes32 digest, bytes calldata signature)
        internal
        view
        returns (bool)
    {
        address module = address(bytes20(signature[:20]));
        if (module != address(this)) {
            return false;
        }

        (bytes32 keyId, bytes memory passkeySignature) = abi.decode(signature[20:], (bytes32, bytes));
        PublicKey memory publicKey = _publicKeys[msg.sender][keyId];
        
        if (publicKey.x == 0 || publicKey.y == 0) {
            return false;
        }

        WebAuthn.WebAuthnAuth memory auth = abi.decode(passkeySignature, (WebAuthn.WebAuthnAuth));
        return WebAuthn.verify({challenge: abi.encode(digest), requireUV: false, webAuthnAuth: auth, x: publicKey.x, y: publicKey.y});
    }

    function validateUserOp(UserOperation calldata userOp, bytes32 digest)
        external
        view
        override
        returns (uint256 validationData)
    {
        if (_validatePasskeySignature(digest, userOp.signature)) {
            return 0;
        }

        return 1;
    }

    function callback(UserOperation calldata, bytes32) external override {}

    function isValidSignature(bytes32 digest, bytes calldata signature)
        public
        view
        override
        returns (bytes4 magicValue)
    {
        if (_validatePasskeySignature(digest, signature)) {
            return this.isValidSignature.selector;
        } else {
            return 0x0000;
        }
    }

    function getPublicKey(address user, bytes32 keyId) external view returns (PublicKey memory) {
        return _publicKeys[user][keyId];
    }

    function getWallet(bytes32 keyId) external view returns (address) {
        return _wallets[keyId];
    }
}
