// SPDX-License-Identifier: Apache
pragma solidity ^0.8.0;

import "account-abstraction/interfaces/UserOperation.sol";
import "openzeppelin/interfaces/IERC1271.sol";

interface IKeyStore is IERC1271 {
    function validateUserOp(uint256 walletIndex, UserOperation calldata userOp, bytes32 userOpHash) external returns(uint256);
}