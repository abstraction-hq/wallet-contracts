// SPDX-License-Identifier: Apache
pragma solidity ^0.8.0;

interface IVerifier {
    function verify(bytes32 hash, bytes memory publicKey, bytes memory signature) external view returns (bool);
}