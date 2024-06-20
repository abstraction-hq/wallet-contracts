// SPDX-License-Identifier: Apache
pragma solidity ^0.8.0;

import "../interfaces/IModule.sol";
import "../interfaces/IWallet.sol";

import {WebAuthn} from "../libraries/WebAuthn.sol";

contract PasskeyModuleFactory {
    function create(uint256 x, uint256 y, bytes32 salt) external returns (PasskeyModule) {
        return new PasskeyModule{salt: salt}(x, y);
    }
}

contract PasskeyModule is IModule {
    uint256 immutable public x;
    uint256 immutable public y;

    constructor(uint256 inputX, uint256 inputY) {
        x = inputX;
        y = inputY;
    }

    function validateUserOp(UserOperation calldata userOp, bytes32 digest)
        external
        view
        override
        returns (uint256 validationData)
    {
        address module = address(bytes20(userOp.signature[:20]));
        require(module == address(this), "invalid module");

        bytes memory signature = userOp.signature[20:];

        if (this.isValidSignature.selector == isValidSignature(digest, signature)) {
            return 0;
        }

        return 1;
    }

    function callback(UserOperation calldata, bytes32) external override {}

    function isValidSignature(bytes32 digest, bytes memory signature) public view override returns (bytes4 magicValue) {
        WebAuthn.WebAuthnAuth memory auth = abi.decode(signature, (WebAuthn.WebAuthnAuth));

        if (WebAuthn.verify({challenge: abi.encode(digest), requireUV: false, webAuthnAuth: auth, x: x, y: y})) {
            return this.isValidSignature.selector;
        } else {
            return 0x0000;
        }

    }
}