// SPDX-License-Identifier: Apache
pragma solidity ^0.8.0;

interface IWalletFactory {
    function calculateWalletAddress(address keyStore, uint256 walletIndex) external view returns (address);
}
