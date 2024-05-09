// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "openzeppelin/utils/StorageSlot.sol";

library WalletStorage {
    bytes32 public constant KEYSTORE_POSITION = keccak256("contracts.v1.key-manage");
    bytes32 public constant FACTORY_POSITION = keccak256("contracts.v1.factory");

    function getAddress(bytes32 key) internal view returns(address) {
        return StorageSlot.getAddressSlot(key).value;
    }

    function setAddress(bytes32 key, address value) internal {
        StorageSlot.getAddressSlot(key).value = value;
    }
}