// SPDX-License-Identifier: Apache
pragma solidity ^0.8.0;

import {Script, console2} from "forge-std/Script.sol";

import "forge-std/console.sol";
import "account-abstraction/core/EntryPoint.sol";
import "../src/GenericFactory.sol";

contract Deployer is Script {
    function setUp() external {}

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("DEPLOYER_PRIVATE_KEY");
        address exitedEntryPoint = vm.envAddress("ENTRY_POINT");
        require(exitedEntryPoint != address(0), "ENTRY_POINT is required");
        vm.startBroadcast(deployerPrivateKey);

        GenericFactory factory = new GenericFactory();
        console.log("Generic factory: ", address(factory));

        vm.stopBroadcast();
    }
}
