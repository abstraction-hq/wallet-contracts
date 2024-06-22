// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "account-abstraction/core/EntryPoint.sol";

import "../../src/modules/Passkey.sol";
import "../../src/libraries/WebAuthn.sol";
import "../../src/WalletFactory.sol";
import "forge-std/Test.sol";
import "forge-std/console.sol";

contract PasskeyModuleTest is Test {
    PasskeyModule passkeyModule;
    WalletFactory walletFactory;

    function setUp() external {
        EntryPoint entryPoint = new EntryPoint();
        walletFactory = new WalletFactory(address(entryPoint));
    }

    function testLogPasskeyModuleCreationCodeHash() external view {
        console.logBytes32(keccak256(type(PasskeyModule).creationCode));
    }

    function testPassKey() external {
        bytes32 salt = keccak256("testCreateWalletWithPasskey");
        passkeyModule = walletFactory.createPasskey(
            28203248099655634232680422976510411012986437076966613883671554831358983509938,
            79473938854726638551736530376995476499049493858003728502280535141260854783821,
            salt
        );
        bytes memory signature =
            hex"00000000000000000000000000000000000000000000000000000000000000c0000000000000000000000000000000000000000000000000000000000000012000000000000000000000000000000000000000000000000000000000000000170000000000000000000000000000000000000000000000000000000000000001eb6f6689e7b96f60dcae3542888f9d094a9abb8e04bd391104d6ee79a9f0967d3bc293dc51c51b23f9063ae81bb2e4a99b520f5f04cda804f0dd80b4c8d7f353000000000000000000000000000000000000000000000000000000000000002549960de5880e8c687434170f6476605b8fe4aeb9a28632c7995cf3ba831d97631d0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000867b2274797065223a22776562617574686e2e676574222c226368616c6c656e6765223a22644c4836595a6f78345332616a6f4e4a384c374d47734657436c75584c6258514a62306e466c7377685930222c226f726967696e223a22687474703a2f2f6c6f63616c686f73743a33303030222c2263726f73734f726967696e223a66616c73657d0000000000000000000000000000000000000000000000000000";
        bytes4 returnValue = passkeyModule.isValidSignature(
            0x74b1fa619a31e12d9a8e8349f0becc1ac1560a5b972db5d025bd27165b30858d, signature
        );

        require(returnValue == passkeyModule.isValidSignature.selector, "signature should be valid");
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
