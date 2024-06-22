// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "account-abstraction/core/EntryPoint.sol";
import "account-abstraction/interfaces/IEntryPoint.sol";

import "../src/WalletFactory.sol";
import "../src/libraries/CustomERC1967.sol";
import "../src/Wallet.sol";
import "../src/modules/Passkey.sol";

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

    function testCreateWalletWithPasskey() external {
        bytes32 salt = keccak256("testCreateWalletWithPasskey");
        uint256 x = 28203248099655634232680422976510411012986437076966613883671554831358983509938;
        uint256 y = 79473938854726638551736530376995476499049493858003728502280535141260854783821;

        Wallet wallet = walletFactory.createWalletWithPasskey(x, y, salt);
        PasskeyModule passkeyModule = PasskeyModule(walletFactory.getPasskeyAddress(x, y));

        require(wallet.isValidKey(address(passkeyModule)), "passkey module should be valid key");
        require(passkeyModule.x() == x, "x should be equal");
        require(passkeyModule.y() == y, "y should be equal");
    }

    function testComputeAddress() external {
        bytes32 salt = keccak256("test wallet");
        address walletAddress = walletFactory.getWalletAddress(salt);

        Wallet wallet = walletFactory.createWallet(address(this), salt);

        require(walletAddress == address(wallet), "wallet address should be equal");
    }
}
