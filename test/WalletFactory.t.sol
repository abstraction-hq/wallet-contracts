// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "account-abstraction/core/EntryPoint.sol";
import "account-abstraction/interfaces/IEntryPoint.sol";

import "../src/WalletFactory.sol";
import "../src/libraries/CustomERC1967.sol";
import "../src/Wallet.sol";
import "../src/Bootstrap.sol";
import "../src/modules/Passkey.sol";

import "forge-std/Test.sol";
import "forge-std/console.sol";

contract WalletFactoryTest is Test {
    EntryPoint entryPoint;
    WalletFactory walletFactory;
    PasskeyModule passkey;
    Bootstrap bootstrap;

    function setUp() external {
        entryPoint = new EntryPoint();
        walletFactory = new WalletFactory(address(entryPoint));
        passkey = new PasskeyModule();
        bootstrap = new Bootstrap(address(passkey));
    }

    function testCreateWalletWithPasskey() external {
        bytes32 salt = keccak256("testCreateWalletWithPasskey");
        uint256 x = 28203248099655634232680422976510411012986437076966613883671554831358983509938;
        uint256 y = 79473938854726638551736530376995476499049493858003728502280535141260854783821;
        
        bytes memory initData = abi.encode(address(bootstrap), abi.encodeWithSignature("init(bytes32,uint256,uint256)", salt, x, y));

        Wallet wallet = walletFactory.createWallet(initData, salt);

        require(wallet.isValidKey(address(passkey)), "passkey module should be valid key");
        PasskeyModule.PublicKey memory publicKey = passkey.getPublicKey(address(wallet), salt);
        require(publicKey.x == x, "x should be equal");
        require(publicKey.y == y, "y should be equal");
    }

    // function testComputeAddress() external {
    //     bytes32 salt = keccak256("test wallet");
    //     address walletAddress = walletFactory.getWalletAddress(salt);
    //     Wallet wallet = walletFactory.createWallet(address(this), salt);

    //     require(walletAddress == address(wallet), "wallet address should be equal");
    // }
}
