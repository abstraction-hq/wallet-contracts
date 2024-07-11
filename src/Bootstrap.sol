// SPDX-License-Identifier: Apache
pragma solidity ^0.8.0;

import "forge-std/console.sol";
import "./Wallet.sol";

contract Bootstrap is Wallet {
    address public immutable passKeyModule;

    constructor(address passkey) Wallet(address(0)) {
        passKeyModule = passkey;
    }

    function _setInitKey() internal {
        _setKey(SENTINEL_ADDRESS, passKeyModule);
        _setKey(passKeyModule, SENTINEL_ADDRESS);
        _increaseTotalKey();
    }

    function _registerPasskey(bytes32 key, uint256 x, uint256 y) internal {
        (bool success,) =
            passKeyModule.call(abi.encodeWithSignature("registerPublicKey(bytes32,uint256,uint256)", key, x, y));
        
        require(success, "Bootstrap: failed to register public key");
    }

    function init(bytes32 key, uint256 x, uint256 y) external {
        _registerPasskey(key, x, y);
        _setInitKey();
    }
}
