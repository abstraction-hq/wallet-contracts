// SPDX-License-Identifier: Apache
pragma solidity 0.7.4;

import "./interfaces/IWallet.sol";

contract Wallet {
    mapping(address => bool) private _admins;
}