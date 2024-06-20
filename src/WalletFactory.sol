// SPDX-License-Identifier: Apache
pragma solidity ^0.8.0;

import "openzeppelin/utils/Create2.sol";
import "openzeppelin/proxy/ERC1967/ERC1967Proxy.sol";

import "./interfaces/IWalletFactory.sol";
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
        address payable walletAddress = getWalletAddress(initKey, salt);
        uint256 codeSize = walletAddress.code.length;
        if (codeSize > 0) {
            return Wallet(walletAddress);
        }

        new ERC1967Proxy{ salt: salt }(address(walletImplement), abi.encodeWithSignature("__Wallet_init(address)", initKey));

        return Wallet(walletAddress);
    }

    function createWallet(address initKey, bytes32 salt) external returns (Wallet) {
        return _createWallet(initKey, salt);
    }

    function getWalletAddress(address initKey, bytes32 salt) public view returns (address payable) {
        return payable(
            Create2.computeAddress(
                salt,
                keccak256(
                    abi.encodePacked(
                        type(ERC1967Proxy).creationCode,
                        abi.encode(address(walletImplement), abi.encodeWithSignature("__Wallet_init(address)", initKey))
                    )
                )
            )
        );
    }
}
