// SPDX-License-Identifier: Apache
pragma solidity ^0.8.13;

import "./interfaces/IWallet.sol";

contract Wallet {
    mapping(address => bool) private _admins;
}