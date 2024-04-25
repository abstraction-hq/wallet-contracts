// SPDX-License-Identifier: Apache
pragma solidity ^0.8.0;

contract Wallet {
    address public keyStore;
    constructor(address entryPoint) {

    }

    function init(address initKeyStore) external {
        keyStore = initKeyStore;
    }
}
