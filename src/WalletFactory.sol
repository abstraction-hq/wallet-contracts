// SPDX-License-Identifier: Apache
pragma solidity ^0.8.0;

import "openzeppelin/utils/Create2.sol";

import "./interfaces/IWalletFactory.sol";
import "./libraries/CustomERC1967.sol";
import "./Wallet.sol";

/**
 * @title Wallet Factory
 * @author imduchuyyy
 * @notice wallet factory use to create new wallet base on our custom ERC1967Proxy
 */
contract WalletFactory is IWalletFactory {
    Wallet public immutable walletImplement;

    constructor(address entryPoint) {
        walletImplement = new Wallet(entryPoint);
    }

    function _createWallet(address initKey, bytes32 salt) internal returns (Wallet) {
        address payable walletAddress = getWalletAddress(salt);
        uint256 codeSize = walletAddress.code.length;
        if (codeSize > 0) {
            return Wallet(walletAddress);
        }

        CustomERC1967 proxy = new CustomERC1967{ salt: salt }();
        proxy.initialize(address(walletImplement), abi.encodeWithSignature("__Wallet_init(address)", initKey));

        return Wallet(walletAddress);
    }

    function createWallet(address initKey, bytes32 salt) external returns (Wallet) {
        return _createWallet(initKey, salt);
    }

    function getWalletAddress(bytes32 salt) public view returns (address payable) {
        return payable(
            Create2.computeAddress(
                salt,
                keccak256(type(CustomERC1967).creationCode)
            )
        );
    }
}
