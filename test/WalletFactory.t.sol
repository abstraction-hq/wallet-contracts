// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "account-abstraction/core/EntryPoint.sol";
import "account-abstraction/interfaces/IEntryPoint.sol";
import "openzeppelin/proxy/ERC1967/ERC1967Proxy.sol";
import "../src/WalletFactory.sol";
import "../src/Wallet.sol";
import "./ERC4337Utils.sol";
import "forge-std/Test.sol";
import "forge-std/console.sol";

using ERC4337Utils for EntryPoint;

contract WalletFactoryTest is Test {
    function setUp() external {}

    function testLog() external view {
        console.logBytes32(keccak256(type(ERC1967Proxy).creationCode));
    }
}
