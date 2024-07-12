// SPDX-License-Identifier: Apache
pragma solidity ^0.8.0;

import "../src/GenericFactory.sol";

contract BaseDeployer {
    GenericFactory public genericFactory = GenericFactory(0xbC82703bDbE098773059957837016b8CA7374992);
}