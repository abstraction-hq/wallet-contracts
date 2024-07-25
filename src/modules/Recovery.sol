// SPDX-License-Identifier: Apache
pragma solidity ^0.8.0;

// import "../interfaces/IModule.sol";
// import "../interfaces/IWallet.sol";

// contract RecoveryModuleFactory {
//     event CreateRecoveryModule(address wallet, address module);
//     function create() external returns (address) {
//         RecoveryModule module = new RecoveryModule();
//         module.init(msg.sender);
//         return address(module);
//     }
// }

// contract RecoveryModule is IModule {
//     uint256 internal constant SIG_VALIDATION_FAILED = 1;

//     struct WalletConfig {
//         uint256 threshold;
//         uint256 minPowerToOpenTicket;
//         uint256 delayTime;
//     }

//     enum TicketStatus {
//         Initial,
//         Pass
//     }

//     struct Ticket {
//         bool isCreated;
//         TicketStatus status;
//         uint256 totalVote;
//         uint256 startBlock;
//         address newKey;
//     }
    
//     mapping(address => WalletConfig) private _configs;

//     mapping(address => mapping(address => uint256)) private _guardianPowers;
//     mapping(address => uint256) private _currentTicketNum;
//     mapping(address => mapping(uint256 => mapping(uint256 => Ticket))) private _tickets; // wallet => currentTicketNum => version => ticket
//     mapping(address => mapping(address => mapping(uint256 => bool))) private _isGuardianVoted;

//     event SetWalletConfig(address wallet, WalletConfig config);
//     event TicketOpened(address wallet, uint256 ticketNum, uint256 version, address creator, Ticket ticket);
//     event TicketClosed(address wallet, uint256 ticketNum);
//     event TicketVoted(address wallet, uint256 tickedNum, address voter);
//     event SetGuardianVotePower(address wallet, address guardian, uint256 votePower);

//     function _decodeTicketNum(bytes calldata signature) internal view returns (uint256) {
//         address module = address(bytes20(signature[:20]));
//         require(module == address(this), "Invalid module");

//         bytes memory ticketNumEncoded = signature[20:];
//         uint256 ticketNum = abi.decode(ticketNumEncoded, (uint256));
//         return ticketNum;
//     }

//     function setWalletConfig(WalletConfig memory config) external {
//         _configs[msg.sender] = config;

//         emit SetWalletConfig(msg.sender, config);
//     }

//     function setGuardian(address guardian, uint256 votePower) external {
//         _guardianPowers[msg.sender][guardian] = votePower;

//         emit SetGuardianVotePower(msg.sender, guardian, votePower);
//     }

//     function openTicket(address wallet, uint256 version, address newKey) external {
//         uint256 guardianPower = _guardianPowers[wallet][msg.sender];
//         require(guardianPower >= _configs[wallet].minPowerToOpenTicket, "Insufficient power");
//         require(!_tickets[wallet][_currentTicketNum[wallet]].isCreated, "Ticket is created");

//         uint256 currentTicketNum = _currentTicketNum[wallet];
//         require(!_tickets[wallet][currentTicketNum].isCreated, "Ticket is created");

//         Ticket storage ticket = _tickets[wallet][ticketNum][version];
//         require(ticket.totalVote == 0, "Ticket exited");
//         require(newKey != address(0), "Invalid new key");

//         ticket.isCreated = true;
//         ticket.status = TicketStatus.Initial;
//         ticket.totalVote = 1;
//         ticket.startBlock = 0;
//         ticket.newKey = newKey;

//         _votedGuardians[ticketNum][msg.sender] = true;

//         emit TicketOpened(wallet, ticketNum, version, msg.sender, ticket);
//     }

//     function closeTicket(address wallet) external {
//         if (wallet != msg.sender) {
//             require(_guardianPowers[wallet][msg.sender] >= _configs[wallet].minPowerToOpenTicket, "Insufficient power");
//         }
//         uint256 currentTicketNum = _currentTicketNum[wallet];
//         delete _tickets[wallet][_currentTicketNum[wallet]];
//         _currentTicketNum[wallet]++;

//         emit TicketClosed(wallet, currentTicketNum);
//     }

//     function voteTicket(address wallet) external {
//         uint256 currentTicketNum = _currentTicketNum[wallet];

//         Ticket storage ticket = _tickets[wallet][currentTicketNum];
//         require(ticket.isCreated, "Ticket not found");
//         require(ticket.status == TicketStatus.Initial, "Ticket not found");
//         require(ticket.newKey != address(0), "Invalid new key");

//         uint256 votePower = _guardianPowers[wallet][msg.sender];
//         require(votePower > 0, "Invalid vote power");

//         require(!_votedGuardians[wallet][ticketNum][msg.sender], "Voted");

//         ticket.totalVote += votePower;
//         _votedGuardians[wallet][ticketNum][msg.sender] = true;

//         if (ticket.totalVote >= _config.threshold) {
//             ticket.status = TicketStatus.Pass;
//             ticket.startBlock = block.number;
//         }

//         emit TicketVoted(ticketNum, msg.sender);
//     }

//     function validateUserOp(UserOperation calldata userOp, bytes32)
//         external
//         view
//         override
//         returns (uint256 validationData)
//     {
//         uint256 ticketNum = _decodeTicketNum(userOp.signature);
//         Ticket memory ticket = _tickets[ticketNum];
//         require(ticket.status == TicketStatus.Pass, "Ticket doesn't pass");
//         require(ticket.startBlock + _config.delayTime > block.number, "Ticket not start yet");

//         bytes memory expectCallData = abi.encodeWithSelector(IWallet.addKey.selector, ticket.newKey, true);

//         require(keccak256(expectCallData) == keccak256(userOp.callData), "Invalid call data");

//         return 0;
//     }

//     function callback(UserOperation calldata userOp, bytes32) external override onlyWallet {
//         uint256 ticketNum = _decodeTicketNum(userOp.signature);
//         delete _tickets[ticketNum];
//     }

//     function isGuardian(address guardian) external view returns (bool) {
//         return _isGuardians[guardian];
//     }

//     function getTicket(uint256 ticketNum) external view returns (Ticket memory) {
//         return _tickets[ticketNum];
//     }

//     function isValidSignature(bytes32, bytes calldata) public view override onlyWallet returns (bytes4 magicValue) {
//         return 0x0000;
//     }
// }
