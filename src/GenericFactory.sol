// SPDX-License-Identifier: Apache
pragma solidity ^0.8.0;

contract GenericFactory {
    function create(bytes memory code) external returns (address addr) {
        assembly {
            addr := create(0, add(code, 0x20), mload(code))
            if iszero(extcodesize(addr)) {
                revert(0, 0)
            }
        }
    }

    function create2(bytes memory code, bytes32 salt) external returns (address addr) {
        assembly {
            addr := create2(0, add(code, 0x20), mload(code), salt)
            if iszero(extcodesize(addr)) {
                revert(0, 0)
            }
        }
    }
}