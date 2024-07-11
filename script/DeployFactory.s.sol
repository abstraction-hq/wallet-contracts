// SPDX-License-Identifier: Apache
pragma solidity ^0.8.0;

import {Script, console2} from "forge-std/Script.sol";

import "forge-std/console.sol";
import "account-abstraction/core/EntryPoint.sol";
import "../src/WalletFactory.sol";
import "../src/Bootstrap.sol";
import "../src/modules/Passkey.sol";

contract Deployer is Script {
    function setUp() external {}

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("DEPLOYER_PRIVATE_KEY");
        address exitedEntryPoint = vm.envAddress("ENTRY_POINT");
        require(exitedEntryPoint != address(0), "ENTRY_POINT is required");
        vm.startBroadcast(deployerPrivateKey);

        console.log("EntryPoint: ", exitedEntryPoint);

        WalletFactory walletFactory = new WalletFactory(exitedEntryPoint);
        PasskeyModule passkey = new PasskeyModule();
        Bootstrap bootstrap = new Bootstrap(address(passkey));

        console.log("WalletFactory: ", address(walletFactory));
        console.log("Passkey: ", address(passkey));
        console.log("Bootstrap: ", address(bootstrap));

        vm.stopBroadcast();
    }
}
