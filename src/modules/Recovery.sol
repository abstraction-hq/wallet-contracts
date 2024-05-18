// SPDX-License-Identifier: Apache
pragma solidity ^0.8.0;

import "../interfaces/IModule.sol";

contract Recovery is IModule {
    struct Config {
        uint16 threshold;
        uint96 delayTime;
    }

    enum TicketStatus {
        Initial,
        Pass
    }

    struct Ticket {
        TicketStatus status;
        uint256 totalVote;
        uint256 startBlock;
        address newKey;
    }

    mapping(address => bool) private _isGuardians;
    mapping(uint256 => Ticket) private _tickets;
    mapping(uint256 => mapping(address => bool)) private _votedGuardians;

    event TicketOpened(uint256 tickedNum, address creator, Ticket ticket);
    event TicketVoted(uint256 tickedNum, address voter);
    event SetGuardian(address guardian, bool status);

    address immutable private _wallet;
    Config private _config;

    constructor(address wallet) {
        _wallet = wallet;
    }

    modifier onlyGuardian() {
        require(_isGuardians[msg.sender], "Only Guardian can call");
        _;
    }

    function _setGuardian(address guardian, bool status) internal {
        _isGuardians[guardian] = status;

        emit SetGuardian(guardian, status);
    }

    function isGuardian(address guardian) external view returns (bool) {
        return _isGuardians[guardian];
    }

    function openTicket(uint256 ticketNum, address newKey) external onlyGuardian {
        Ticket storage ticket = _tickets[ticketNum];
        require(ticket.totalVote == 0, "Ticked exited");

        ticket.status = TicketStatus.Initial;
        ticket.totalVote = 1;
        ticket.startBlock = 0;
        ticket.newKey = newKey;

        _votedGuardians[ticketNum][msg.sender] = true;

        emit TicketOpened(ticketNum, msg.sender, ticket);
    }

    function voteTicket(uint256 ticketNum) external onlyGuardian {
        Ticket storage ticket = _tickets[ticketNum];
        require(ticket.totalVote != 0, "Ticked not found");
        require(!_votedGuardians[ticketNum][msg.sender], "Voted");

        ticket.totalVote++;
        
        if (ticket.totalVote >= _config.threshold) {
            ticket.status = TicketStatus.Pass;
            ticket.startBlock = block.number;
        }
    }

    function validateUserOp(UserOperation calldata userOp, bytes32 userOpHash)
        external
        override
        returns (uint256 validationData)
    {
        require(msg.sender == _wallet, "Wrong wallet");
    }

    function isValidSignature(bytes32 hash, bytes calldata signature)
        public
        view
        override
        returns (bytes4 magicValue)
    {
        return 0x0000;
    }

}
