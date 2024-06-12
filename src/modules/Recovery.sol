// SPDX-License-Identifier: Apache
pragma solidity ^0.8.0;

import "../interfaces/IModule.sol";
import "../interfaces/IWallet.sol";

contract RecoveryModuleFactory {
    function create(uint16 threshold, uint96 delayTime) external returns (RecoveryModule) {
        return new RecoveryModule(msg.sender, threshold, delayTime);
    }
}

contract RecoveryModule is IModule {
    uint256 internal constant SIG_VALIDATION_FAILED = 1;

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

    address private immutable _wallet;
    Config private _config;

    constructor(address wallet, uint16 threshold, uint96 delayTime) {
        _wallet = wallet;

        _config.threshold = threshold;
        _config.delayTime = delayTime;
    }

    modifier onlyGuardian() {
        require(_isGuardians[msg.sender], "Only Guardian can call");
        _;
    }

    modifier onlyWallet() {
        require(msg.sender == _wallet, "Only wallet can call");
        _;
    }

    function _setGuardian(address guardian, bool status) internal {
        _isGuardians[guardian] = status;

        emit SetGuardian(guardian, status);
    }

    function _decodeTicketNum(bytes calldata signature) internal view returns (uint256) {
        address module = address(bytes20(signature[:20]));
        require(module == address(this), "Invalid module");

        bytes memory ticketNumEncoded = signature[20:];
        uint256 ticketNum = abi.decode(ticketNumEncoded, (uint256));
        return ticketNum;
    }

    function setGuardian(address guardian, bool status) external onlyWallet {
        _setGuardian(guardian, status);
    }

    function openTicket(uint256 ticketNum, address newKey) external onlyGuardian {
        Ticket storage ticket = _tickets[ticketNum];
        require(ticket.totalVote == 0, "Ticket exited");
        require(newKey != address(0), "Invalid new key");

        ticket.status = TicketStatus.Initial;
        ticket.totalVote = 1;
        ticket.startBlock = 0;
        ticket.newKey = newKey;

        _votedGuardians[ticketNum][msg.sender] = true;

        emit TicketOpened(ticketNum, msg.sender, ticket);
    }

    function voteTicket(uint256 ticketNum) external onlyGuardian {
        Ticket storage ticket = _tickets[ticketNum];
        require(ticket.status == TicketStatus.Initial, "Ticket not found");
        require(ticket.newKey != address(0), "Invalid new key");
        require(!_votedGuardians[ticketNum][msg.sender], "Voted");

        ticket.totalVote++;

        if (ticket.totalVote >= _config.threshold) {
            ticket.status = TicketStatus.Pass;
            ticket.startBlock = block.number;
        }

        emit TicketVoted(ticketNum, msg.sender);
    }

    function validateUserOp(UserOperation calldata userOp, bytes32)
        external
        override
        onlyWallet
        returns (uint256 validationData)
    {
        uint256 ticketNum = _decodeTicketNum(userOp.signature);
        Ticket memory ticket = _tickets[ticketNum];
        require(ticket.status == TicketStatus.Pass, "Ticket doesn't pass");
        require(ticket.startBlock + _config.delayTime > block.number, "Ticket not start yet");

        bytes memory expectCallData = abi.encodeWithSelector(IWallet.addKey.selector, ticket.newKey, true);

        require(keccak256(expectCallData) == keccak256(userOp.callData), "Invalid call data");

        return 0;
    }

    function callback(UserOperation calldata userOp, bytes32) external override {
        uint256 ticketNum = _decodeTicketNum(userOp.signature);
        delete _tickets[ticketNum];
    }

    function isGuardian(address guardian) external view returns (bool) {
        return _isGuardians[guardian];
    }

    function getTicket(uint256 ticketNum) external view returns (Ticket memory) {
        return _tickets[ticketNum];
    }

    function isValidSignature(bytes32, bytes calldata) public view override onlyWallet returns (bytes4 magicValue) {
        return 0x0000;
    }
}
