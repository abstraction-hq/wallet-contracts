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

        console.log("EntryPoint: ", exitedEntryPoint);

        bytes memory walletFactoryCode = abi.encodePacked(type(WalletFactory).creationCode, abi.encode(exitedEntryPoint));
        address walletFactory = genericFactory.create2(walletFactoryCode, salt);

        bytes memory passkeyCode = type(PasskeyModule).creationCode;
        address passkey = genericFactory.create2(passkeyCode, salt);

        bytes memory bootstrapCode = abi.encodePacked(type(Bootstrap).creationCode, abi.encode(passkey));
        address bootstrap = genericFactory.create2(bootstrapCode, salt);

        console.log("WalletFactory: ", walletFactory);
        console.log("Passkey: ", passkey);
        console.log("Bootstrap: ", bootstrap);

        vm.stopBroadcast();
    }
}
