// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

interface IKeyStore {
    function addKey(address key, uint256 walletIndex) external;
    function removeKey(address prevKey, address key, uint256 walletIndex) external;
    function getKeys() external view returns (address[] memory keys);
    function init(address initKey) external;
    function isValidKey(address key) external view returns (bool);
}
