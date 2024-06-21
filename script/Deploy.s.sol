// SPDX-License-Identifier: Apache
pragma solidity ^0.8.0;

import {Script, console2} from "forge-std/Script.sol";

import "account-abstraction/core/EntryPoint.sol";
import "../src/WalletFactory.sol";
import "../src/modules/Passkey.sol";

contract Deployer is Script {
    function setUp() external {}

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("DEPLOYER_PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        EntryPoint entryPoint = new EntryPoint();
        new WalletFactory(address(entryPoint));

        new PasskeyModuleFactory();

        vm.stopBroadcast();
    }
}
