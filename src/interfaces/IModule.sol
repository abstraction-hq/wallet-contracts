// SPDX-License-Identifier: Apache
pragma solidity ^0.8.0;

import "account-abstraction/core/BaseAccount.sol";
import "openzeppelin/interfaces/IERC1271.sol";

interface IModule is IERC1271 {
    function validateUserOp(UserOperation calldata userOp, bytes32 userOpHash)
        external
        returns (uint256 validationData);

    function callback(UserOperation calldata userOp, bytes32 userOpHash) external;
}
