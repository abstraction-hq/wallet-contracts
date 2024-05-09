// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "account-abstraction/core/EntryPoint.sol";
import "account-abstraction/interfaces/IEntryPoint.sol";
import "../src/WalletFactory.sol";
import "../src/Wallet.sol";
import "./ERC4337Utils.sol";
import "forge-std/Test.sol";
import "forge-std/console.sol";

using ERC4337Utils for EntryPoint;

contract WalletTest is Test {
    EntryPoint entryPoint;
    WalletFactory walletFactory;
    Wallet wallet;

    address owner;
    uint256 ownerKey;

    address payable beneficiary;

    function setUp() external {
        ownerKey = uint256(keccak256("owner"));
        owner = vm.addr(ownerKey);
        entryPoint = new EntryPoint();

        walletFactory = new WalletFactory(address(entryPoint));
        beneficiary = payable(address(vm.addr(uint256(keccak256("beneficiary")))));

        wallet = Wallet(walletFactory.getWalletAddress(owner));

        vm.deal(address(wallet), 1 ether);

        UserOperation memory op = entryPoint.fillUserOp(address(wallet), "");
        op.initCode = abi.encodePacked(
            bytes20(address(walletFactory)),
            abi.encodeWithSelector(walletFactory.createWallet.selector, owner, uint256(0), bytes32(uint256(1)))
        );
        op.signature = abi.encodePacked(bytes20(owner), entryPoint.signUserOpHash(vm, ownerKey, op));

        UserOperation[] memory ops = new UserOperation[](1);
        ops[0] = op;

        entryPoint.handleOps(ops, beneficiary);
    }

    function test_SendEth() external {
        vm.deal(address(wallet), 1 ether);

        UserOperation memory op = entryPoint.fillUserOp(address(wallet), "");
        op.callData = abi.encodeWithSelector(wallet.execute.selector, beneficiary, 1, "");
        op.signature = abi.encodePacked(bytes20(owner), entryPoint.signUserOpHash(vm, ownerKey, op));

        UserOperation[] memory ops = new UserOperation[](1);
        ops[0] = op;

        entryPoint.handleOps(ops, beneficiary);
    }

    function test_setKey() external {
        uint256 owner2 = uint256(keccak256("owner2"));
        address owner2Address = vm.addr(owner2);

        vm.deal(address(wallet), 1 ether);

        UserOperation memory op = entryPoint.fillUserOp(address(wallet), "");
        op.callData = abi.encodeWithSelector(
            wallet.addKey.selector,
            owner2Address,
            uint256(0)
        );
        op.signature = abi.encodePacked(bytes20(owner), entryPoint.signUserOpHash(vm, ownerKey, op));

        UserOperation[] memory ops = new UserOperation[](1);
        ops[0] = op;

        entryPoint.handleOps(ops, beneficiary);
        require(wallet.isValidKey(owner2Address), "Fail to add key");
        _logKey();
    }

    function test_removeKey() external {
        uint256 owner2 = uint256(keccak256("owner2"));
        address owner2Address = vm.addr(owner2);

        vm.deal(address(wallet), 1 ether);

        UserOperation memory op = entryPoint.fillUserOp(address(wallet), "");
        op.callData = abi.encodeWithSelector(
            wallet.addKey.selector,
            owner2Address,
            uint256(0)
        );
        op.signature = abi.encodePacked(bytes20(owner), entryPoint.signUserOpHash(vm, ownerKey, op));

        UserOperation[] memory ops = new UserOperation[](1);
        ops[0] = op;

        entryPoint.handleOps(ops, beneficiary);
        require(wallet.isValidKey(owner2Address), "Fail to add key");
        _logKey();

        op.nonce = entryPoint.getNonce(address(wallet), 0);
        op.initCode = "";
        op.callData = abi.encodeWithSelector(
            wallet.removeKey.selector,
            address(0x1),
            owner2Address,
            uint256(0)
        );
        op.signature = abi.encodePacked(bytes20(owner), entryPoint.signUserOpHash(vm, ownerKey, op));
        ops[0] = op;

        entryPoint.handleOps(ops, beneficiary);
        require(!wallet.isValidKey(owner2Address), "Fail to add key");
        _logKey();
    }

    function _logKey() internal view {
        address[] memory keys = wallet.getKeys();

        console.log("Keys of", address(wallet));
        for (uint256 i; i < keys.length; i++) {
            console.log("-----", keys[i]);
        }
    }
}
