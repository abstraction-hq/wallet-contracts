// SPDX-License-Identifier: Apache
pragma solidity ^0.8.0;

import "../src/GenericFactory.sol";

contract BaseDeployer {
    GenericFactory public genericFactory = GenericFactory(0x9aE7a293de3D5789Cd24324C167B7BC98A0c70B7);
}