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
            74158313479311325423538166910535358860764730666614613653075492090963525475244,
            98651699245633844959636559008231914818371239173279442999209524086811480785714,
            salt
        );

        bytes memory signature =
            hex"000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000000c00000000000000000000000000000000000000000000000000000000000000120000000000000000000000000000000000000000000000000000000000000001700000000000000000000000000000000000000000000000000000000000000011ae54d1d034cf5421bad3557c6c80437c68bf1010839fe84af069b4a25a51e308b88e57d1732a6f0c512dd1df4b266d7144a839046ca90f4ad2e3efbf989ef51000000000000000000000000000000000000000000000000000000000000002549960de5880e8c687434170f6476605b8fe4aeb9a28632c7995cf3ba831d97631d0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000867b2274797065223a22776562617574686e2e676574222c226368616c6c656e6765223a224735394c6a5a304e6c5f4341574b5965564c4479465a62354d38682d557947686f5835395a396b56396830222c226f726967696e223a22687474703a2f2f6c6f63616c686f73743a33303030222c2263726f73734f726967696e223a66616c73657d0000000000000000000000000000000000000000000000000000";
        bytes4 returnValue = passkeyModule.isValidSignature(
            0x1b9f4b8d9d0d97f08058a61e54b0f21596f933c87e5321a1a17e7d67d915f61d, signature
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
