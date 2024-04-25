// SPDX-License-Identifier: Apache
pragma solidity ^0.8.0;

import "openzeppelin/utils/Create2.sol";
import "openzeppelin/proxy/ERC1967/ERC1967Proxy.sol";
import "openzeppelin/proxy/Clones.sol";

import "./libraries/WalletProxy.sol";
import "./KeyStore.sol";

import "./Wallet.sol";

/**
 * @title Ethereum Wallet Factory
 * @author Terry
 * @notice wallet factory use to create new wallet base on our custom ERC1967Proxy
 */
contract EthereumWalletFactory {
    Wallet public immutable walletImplement;
    KeyStore public immutable keyStoreImplement;

    constructor(address entryPoint) {
        walletImplement = new Wallet(entryPoint);
        keyStoreImplement = new KeyStore();
    }

    function _createKeyStore(address initKey, bytes32 salt) internal returns (KeyStore) {
        address payable keyStoreAddress = getKeyStoreAddress(salt);
        uint codeSize = keyStoreAddress.code.length;
        if (codeSize > 0) {
            return KeyStore(keyStoreAddress);
        }

        // using Clones proxy to saving gas cost
        Clones.cloneDeterministic(address(keyStoreImplement), salt);
        KeyStore(keyStoreAddress).init(initKey);

        return KeyStore(keyStoreAddress);
    }

    function _createWallet(address keyStore, uint256 walletIndex) internal returns (EthereumWallet) {
        address payable walletAddress = getWalletAddress(keyStore, walletIndex);
        uint codeSize = walletAddress.code.length;
        if (codeSize > 0) {
            return EthereumWallet(walletAddress);
        }

        bytes32 salt = keccak256(abi.encode(keyStore, walletIndex));
        new CustomERC1967{ salt: salt }();
        CustomERC1967(walletAddress).init((address(walletImplement)), abi.encodeCall(EthereumWallet.init, (keyStore)));

        return EthereumWallet(walletAddress);
    }

    function createWalletWithKeyStore(address keyStore, uint256 walletIndex) external returns (EthereumWallet) {
        return _createWallet(keyStore, walletIndex);
    }

    function createWallet(address initKey, uint256 walletIndex, bytes32 keyStoreSalt) external returns (EthereumWallet) {
        KeyStore keyStore = _createKeyStore(initKey, keyStoreSalt);
        return _createWallet(address(keyStore), walletIndex);
    }

    function getWalletAddress(address keyStore, uint256 walletIndex) public view returns (address payable) {
        bytes32 salt = keccak256(abi.encode(keyStore, walletIndex));
        return payable(Create2.computeAddress(salt, keccak256(abi.encodePacked(
            type(CustomERC1967).creationCode,
            ""
        ))));
    }

    function getKeyStoreAddress(bytes32 salt) public view returns (address payable) {
        return payable(Clones.predictDeterministicAddress(address(keyStoreImplement), salt));
    }
}