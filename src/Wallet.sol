// SPDX-License-Identifier: Apache
pragma solidity ^0.8.0;

import "account-abstraction/core/BaseAccount.sol";
import "openzeppelin/proxy/utils/Initializable.sol";

contract Wallet is BaseAccount, Initializable {
    IEntryPoint private immutable _entryPoint;
    address private _keyStore;
    address private _factory;

    constructor(address entryPointAddress) {
        _entryPoint = IEntryPoint(entryPointAddress);
    }

    function __Wallet_init(address keystore) external initializer {
        _keyStore = keystore;
        _factory = msg.sender;
    }

    function entryPoint() public view override returns (IEntryPoint) {
        return _entryPoint;
    }

    function _validateSignature(UserOperation calldata userOp, bytes32 userOpHash)
        internal
        override
        returns (uint256 validationData)
    {
        return 1;
    }
}
