// SPDX-License-Identifier: Apache
pragma solidity ^0.8.0;

import "openzeppelin/utils/Create2.sol";

import "./interfaces/IWalletFactory.sol";
import "./libraries/CustomERC1967.sol";

import "./modules/Passkey.sol";
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

    // Only create new passkey module not return exited module
    function _createPasskeyModule(uint256 x, uint256 y, bytes32 salt) internal returns (PasskeyModule) {
        PasskeyModule passkeyModule = new PasskeyModule{salt: salt}();
        passkeyModule.initialize(x, y);
        return passkeyModule;
    }

    function createWallet(address initKey, bytes32 salt) external returns (Wallet) {
        return _createWallet(initKey, salt);
    }

    function createPasskey(uint256 x, uint256 y, bytes32 salt) external returns (PasskeyModule) {
        return _createPasskeyModule(x, y, salt);
    }

    function createWalletWithPasskey(uint256 x, uint256 y, bytes32 salt) external returns (Wallet) {
        PasskeyModule passkeyModule = _createPasskeyModule(x, y, salt);
        return _createWallet(address(passkeyModule), salt);
    }

    function multicall(bytes[] calldata data) external returns (bytes[] memory results) {
        results = new bytes[](data.length);
        for (uint256 i = 0; i < data.length; i++) {
            (bool success, bytes memory result) = address(this).delegatecall(data[i]);
            require(success, "Multicall: call failed");
            results[i] = result;
        }
    }

    function getPasskeyModuleCreationCodeHash() public pure returns(bytes32) {
        return keccak256(type(PasskeyModule).creationCode);
    }

    function getWalletCreationCodeHash() public pure returns(bytes32) {
        return keccak256(type(CustomERC1967).creationCode);
    }

    function getWalletAddress(bytes32 salt) public view returns (address payable) {
        return payable(
            Create2.computeAddress(
                salt,
                getWalletCreationCodeHash()
            )
        );
    }

    function getPasskeyAddress(bytes32 salt) public view returns (address) {
        return payable(
            Create2.computeAddress(
                salt,
                getPasskeyModuleCreationCodeHash()
            )
        );
    }
}
