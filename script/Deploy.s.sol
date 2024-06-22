// SPDX-License-Identifier: Apache
pragma solidity ^0.8.0;

import {Script, console2} from "forge-std/Script.sol";

import "forge-std/console.sol";
import "account-abstraction/core/EntryPoint.sol";
import "../src/WalletFactory.sol";
import "../src/modules/Passkey.sol";

contract Deployer is Script {
    function setUp() external {}

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("DEPLOYER_PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        EntryPoint entryPoint = new EntryPoint();
        console.log("EntryPoint: ", address(entryPoint));

        WalletFactory walletFactory = new WalletFactory(address(entryPoint));
        console.log("WalletFactory: ", address(walletFactory));

        PasskeyModuleFactory passkeyModuleFactory = new PasskeyModuleFactory();
        console.log("PasskeyModuleFactory: ", address(passkeyModuleFactory));

        vm.stopBroadcast();
    }
}
