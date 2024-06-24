// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "account-abstraction/core/EntryPoint.sol";

import "../../src/modules/Passkey.sol";
import "../../src/libraries/WebAuthn.sol";
import "../../src/WalletFactory.sol";
import "../utils/ERC4337Utils.sol";
import "forge-std/Test.sol";
import "forge-std/console.sol";

using ERC4337Utils for EntryPoint;

contract PasskeyModuleTest is Test {
    EntryPoint entryPoint;
    PasskeyModule passkeyModule;
    WalletFactory walletFactory;

    function setUp() external {
        entryPoint = new EntryPoint();
        walletFactory = new WalletFactory(address(entryPoint));
    }

    function testLogPasskeyModuleCreationCodeHash() external view {
        console.logBytes32(keccak256(type(PasskeyModule).creationCode));
    }

    function testPassKey() external {
        bytes32 salt = keccak256("testCreateWalletWithPasskey");
        passkeyModule = walletFactory.createPasskey(
            0xa60dd7f9d8edc4a6c7e2ad99c360804bb01d3942c7a975da1a33bdb1d136ddab,
            0x2c35b9180fd0f24047974c6cfa8992c20a8f60bf9b337644918c2f163dd5deee,
            salt
        );

        bytes memory signature =
            hex"00000000000000000000000000000000000000000000000000000000000000c00000000000000000000000000000000000000000000000000000000000000120000000000000000000000000000000000000000000000000000000000000001700000000000000000000000000000000000000000000000000000000000000011cf2c8e67f1406348fab3e97670aabd0046c412d46676b639ea590e692011f32e68a1fb29f6060c755d03358f03b1a262672ecd8d609ab279f8c968af20562d1000000000000000000000000000000000000000000000000000000000000002549960de5880e8c687434170f6476605b8fe4aeb9a28632c7995cf3ba831d97631d0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000867b2274797065223a22776562617574686e2e676574222c226368616c6c656e6765223a22456a736c6d51594d4d5f305976646139502d66313341363066586865585072307534373547665565463449222c226f726967696e223a22687474703a2f2f6c6f63616c686f73743a33303030222c2263726f73734f726967696e223a66616c73657d0000000000000000000000000000000000000000000000000000";
        bytes4 returnValue = passkeyModule.isValidSignature(
            0x123b2599060c33fd18bdd6bd3fe7f5dc0eb47d785e5cfaf4bb8ef919f51e1782, signature
        );

        console.log("Is valid signature: ");
        console.logBytes4(returnValue);

        // require(returnValue == passkeyModule.isValidSignature.selector, "signature should be valid");
    }

    function testComputeAddress() external {
        bytes32 salt = keccak256("testCreateWalletWithPasskey");
        uint256 x = 28203248099655634232680422976510411012986437076966613883671554831358983509938;
        uint256 y = 79473938854726638551736530376995476499049493858003728502280535141260854783821;
        address passkeyModuleAddress = walletFactory.getPasskeyAddress(salt);
        passkeyModule = walletFactory.createPasskey(x, y, salt);

        require(passkeyModuleAddress == address(passkeyModule), "passkey module address should be equal");
    }
}
