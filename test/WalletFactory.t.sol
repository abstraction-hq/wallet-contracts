// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "account-abstraction/core/EntryPoint.sol";
import "account-abstraction/interfaces/IEntryPoint.sol";

import "../src/WalletFactory.sol";
import "../src/libraries/CustomERC1967.sol";
import "../src/Wallet.sol";

import "forge-std/Test.sol";
import "forge-std/console.sol";

contract WalletFactoryTest is Test {
    EntryPoint entryPoint;
    WalletFactory walletFactory;

    function setUp() external {
        entryPoint = new EntryPoint();
        walletFactory = new WalletFactory(address(entryPoint));
    }

    function testLogCustomERC1967CreationCodeHash() external view {
        console.logBytes32(keccak256(type(CustomERC1967).creationCode));
    }

    function testComputeAddress() external {
        bytes32 salt = keccak256("test wallet");
        address walletAddress = walletFactory.getWalletAddress(salt);

        Wallet wallet = walletFactory.createWallet(address(this), salt);

        require(walletAddress == address(wallet), "wallet address should be equal");
    }
}
