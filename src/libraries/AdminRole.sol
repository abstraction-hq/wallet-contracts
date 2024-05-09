// SPDX-License-Identifier: Apache
pragma solidity ^0.8.0;

abstract contract AdminRole {
    mapping(address => bool) private _isAdmins;

    event SetAdmin(address admin, bool status);

    modifier onlyAdmin() {
        require(_isAdmins[msg.sender], "Only admin");
        _;
    }

    function _setAdmin(address admin, bool status) internal {
        _isAdmins[admin] = status;

        emit SetAdmin(admin, status);
    }

    function setAdmin(address admin, bool status) external onlyAdmin {
        _setAdmin(admin, status);
    }

    function isAdmin(address admin) external view returns (bool) {
        return _isAdmins[admin];
    }
}
