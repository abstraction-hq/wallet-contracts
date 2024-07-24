// SPDX-License-Identifier: Apache
pragma solidity ^0.8.0;

import {Script, console2} from "forge-std/Script.sol";

import "forge-std/console.sol";
import "account-abstraction/core/EntryPoint.sol";
import "../src/WalletFactory.sol";
import "../src/Bootstrap.sol";
import "../src/modules/Passkey.sol";
import "./BaseDeployer.sol";

contract Deployer is Script, BaseDeployer {
    function setUp() external {}

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("DEPLOYER_PRIVATE_KEY");
        address exitedEntryPoint = vm.envAddress("ENTRY_POINT");
        bytes32 salt = vm.envBytes32("SALT");
        require(exitedEntryPoint != address(0), "ENTRY_POINT is required");
        vm.startBroadcast(deployerPrivateKey);

        bytes memory passkeyCode = type(PasskeyModule).creationCode;
        address passkey = genericFactory.create2(passkeyCode, salt);
        console.log("Passkey: ", passkey);

        vm.stopBroadcast();
    }
}
