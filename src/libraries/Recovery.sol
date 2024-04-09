// SPDX-License-Identifier: Apache
pragma solidity ^0.8.0;

abstract contract Recovery {
    struct Config {
        uint16 threshold;
        uint96 delayTime;
    }

    struct Ticket {
        bool isActive;
        uint256 totalVote;
        uint256 startTime;
        address newAdmin;
    }

    mapping (address => bool) private _isGuardians;
    mapping (uint256 => Ticket) private _tickets;
    mapping (uint256 => mapping(address => bool)) private _votedGuardians;

    event TicketOpened(uint256 tickedNum, address creator, Ticket ticket);
    event TicketVoted(uint256 tickedNum, address voter);
    event SetGuardian(address guardian, bool status);

    modifier onlyGuardian() {
        require(_isGuardians[msg.sender], "Only Guardian can call");
        _;
    }

    function _setGuardian(address guardian, bool status) internal {
        _isGuardians[guardian] = status;

        emit SetGuardian(guardian, status);
    }

    function isGuardian(address guardian) external view returns(bool) {
        return _isGuardians[guardian];
    }

    function openTicket(uint256 ticketNum, address newAdmin) external onlyGuardian {
        Ticket storage ticket = _tickets[ticketNum];
        require(!ticket.isActive, "Ticket exited");

        ticket.isActive = true;
        ticket.totalVote = 1;
        ticket.startTime = 0;
        ticket.newAdmin = newAdmin;

        _votedGuardians[ticketNum][msg.sender] = true;

        emit TicketOpened(ticketNum, msg.sender, ticket);
    }

    function voteTicket(uint256 ticketNum) external onlyGuardian {
        Ticket storage ticket = _tickets[ticketNum];
        require(!ticket.isActive, "Ticket exited");
        require(!_votedGuardians[ticketNum][msg.sender], "Voted");

        ticket.totalVote++;
    }
}