// SPDX-License-Identifier: Apache
pragma solidity ^0.8.0;

import "openzeppelin/utils/Create2.sol";
import "openzeppelin/proxy/ERC1967/ERC1967Proxy.sol";
import "openzeppelin/proxy/Clones.sol";

import "./interfaces/IWalletFactory.sol";
import "./Wallet.sol";

/**
 * @title Wallet Factory
 * @author Terry
 * @notice wallet factory use to create new wallet base on our custom ERC1967Proxy
 */
contract WalletFactory is IWalletFactory {
    Wallet public immutable walletImplement;

    constructor(address entryPoint) {
        walletImplement = new Wallet(entryPoint);
    }

    function _createWallet(address initKey) internal returns (Wallet) {
        address payable walletAddress = getWalletAddress(initKey);
        uint256 codeSize = walletAddress.code.length;
        if (codeSize > 0) {
            return Wallet(walletAddress);
        }

        bytes32 salt = keccak256(abi.encode(initKey));
        new ERC1967Proxy{ salt: salt }(address(walletImplement), abi.encodeWithSignature("__Wallet_init(address)", initKey));

        return Wallet(walletAddress);
    }

    function createWallet(address initKey) external returns (Wallet) {
        return _createWallet(initKey);
    }

    function getWalletAddress(address initKey) public view returns (address payable) {
        bytes32 salt = keccak256(abi.encode(initKey));
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
