// SPDX-License-Identifier: Apache
pragma solidity ^0.8.0;

import "../interfaces/IModule.sol";
import "../interfaces/IWallet.sol";

import {WebAuthn} from "webauthn-sol/WebAuthn.sol";

contract PasskeyModuleFactory {
    function create(bytes32 salt) external returns (PasskeyModule) {
        return new PasskeyModule{salt: salt}();
    }
}

contract PasskeyModule is IModule {
    constructor() {
    }

    function validateUserOp(UserOperation calldata userOp, bytes32)
        external
        view
        override
        returns (uint256 validationData)
    {
        address module = address(bytes20(userOp.signature[:20]));
        require(module == address(this), "invalid module");
        return 0;
    }

    function callback(UserOperation calldata userOp, bytes32) external override {

    }

    function isValidSignature(bytes32 digest, bytes calldata signature) public view override returns (bytes4 magicValue) {
        return 0x0000;
    }
}