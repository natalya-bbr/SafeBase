// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {PausableUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
import {Treasury} from "../Treasury.sol";

contract SafeBaseEscrowV1 is
    Initializable,
    UUPSUpgradeable,
    OwnableUpgradeable,
    PausableUpgradeable
{
    uint256 private _reentrancyStatus;
    enum EscrowState { Created, Funded, Released, Refunded, Disputed, Cancelled }

    struct EscrowData {
        address buyer;
        address seller;
        address mediator;
        address token;
        uint256 amount;
        uint256 deadline;
        EscrowState state;
        bool buyerApproved;
        bool sellerApproved;
        bytes32 paymentId;
        uint256 createdAt;
    }

    Treasury public treasury;
    address public rulesEngine;
    address public registry;

    uint256 public escrowCounter;
    mapping(uint256 => EscrowData) public escrows;
    mapping(bytes32 => uint256) public paymentIdToEscrow;

    event EscrowCreated(
        uint256 indexed escrowId,
        address indexed buyer,
        address indexed seller,
        address token,
        uint256 amount,
        uint256 deadline
    );

    event EscrowFunded(uint256 indexed escrowId, uint256 amount);
    event EscrowReleased(uint256 indexed escrowId, address indexed recipient);
    event EscrowRefunded(uint256 indexed escrowId, address indexed recipient);
    event EscrowDisputed(uint256 indexed escrowId, address indexed initiator);
    event EscrowCancelled(uint256 indexed escrowId);
    event BasePayFundingReceived(uint256 indexed escrowId, bytes32 indexed paymentId);
    event ApprovalGranted(uint256 indexed escrowId, address indexed party);

    error InvalidState();
    error Unauthorized();
    error DeadlineExpired();
    error InvalidAmount();
    error InvalidAddress();
    error EscrowNotFound();
    error AlreadyApproved();

    modifier nonReentrant() {
        require(_reentrancyStatus != 2, "ReentrancyGuard: reentrant call");
        _reentrancyStatus = 2;
        _;
        _reentrancyStatus = 1;
    }

    function initialize(address _owner, address _treasury) public initializer {
        __Ownable_init(_owner);
        __Pausable_init();
        _reentrancyStatus = 1;

        if (_treasury == address(0)) revert InvalidAddress();
        treasury = Treasury(payable(_treasury));
    }

    function setRulesEngine(address _rulesEngine) external onlyOwner {
        if (_rulesEngine == address(0)) revert InvalidAddress();
        rulesEngine = _rulesEngine;
    }

    function setRegistry(address _registry) external onlyOwner {
        if (_registry == address(0)) revert InvalidAddress();
        registry = _registry;
    }

    function createEscrow(
        address _seller,
        address _mediator,
        address _token,
        uint256 _amount,
        uint256 _deadline
    ) external whenNotPaused returns (uint256) {
        if (_seller == address(0)) revert InvalidAddress();
        if (_amount == 0) revert InvalidAmount();
        if (_deadline <= block.timestamp) revert DeadlineExpired();

        uint256 escrowId = ++escrowCounter;

        escrows[escrowId] = EscrowData({
            buyer: msg.sender,
            seller: _seller,
            mediator: _mediator,
            token: _token,
            amount: _amount,
            deadline: _deadline,
            state: EscrowState.Created,
            buyerApproved: false,
            sellerApproved: false,
            paymentId: bytes32(0),
            createdAt: block.timestamp
        });

        emit EscrowCreated(escrowId, msg.sender, _seller, _token, _amount, _deadline);

        return escrowId;
    }

    function fundEscrow(uint256 _escrowId) external payable nonReentrant whenNotPaused {
        EscrowData storage escrow = escrows[_escrowId];
        if (escrow.state != EscrowState.Created) revert InvalidState();
        if (msg.sender != escrow.buyer) revert Unauthorized();

        if (escrow.token == address(0)) {
            if (msg.value != escrow.amount) revert InvalidAmount();
            (bool success, ) = payable(address(treasury)).call{value: msg.value}("");
            require(success, "ETH transfer failed");
        }

        escrow.state = EscrowState.Funded;
        emit EscrowFunded(_escrowId, escrow.amount);
    }

    function fundEscrowWithBasePay(uint256 _escrowId, bytes32 _paymentId) external whenNotPaused {
        EscrowData storage escrow = escrows[_escrowId];
        if (escrow.state != EscrowState.Created) revert InvalidState();

        escrow.state = EscrowState.Funded;
        escrow.paymentId = _paymentId;
        paymentIdToEscrow[_paymentId] = _escrowId;

        emit EscrowFunded(_escrowId, escrow.amount);
        emit BasePayFundingReceived(_escrowId, _paymentId);
    }

    function approveBuyer(uint256 _escrowId) external {
        EscrowData storage escrow = escrows[_escrowId];
        if (escrow.state != EscrowState.Funded) revert InvalidState();
        if (msg.sender != escrow.buyer) revert Unauthorized();
        if (escrow.buyerApproved) revert AlreadyApproved();

        escrow.buyerApproved = true;
        emit ApprovalGranted(_escrowId, msg.sender);
    }

    function approveSeller(uint256 _escrowId) external {
        EscrowData storage escrow = escrows[_escrowId];
        if (escrow.state != EscrowState.Funded) revert InvalidState();
        if (msg.sender != escrow.seller) revert Unauthorized();
        if (escrow.sellerApproved) revert AlreadyApproved();

        escrow.sellerApproved = true;
        emit ApprovalGranted(_escrowId, msg.sender);
    }

    function releaseToSeller(uint256 _escrowId) external nonReentrant whenNotPaused {
        EscrowData storage escrow = escrows[_escrowId];
        if (escrow.state != EscrowState.Funded) revert InvalidState();

        bool isMediator = msg.sender == escrow.mediator && escrow.mediator != address(0);
        bool isBuyer = msg.sender == escrow.buyer;

        if (!isMediator && !isBuyer) revert Unauthorized();
        if (!isMediator && !escrow.buyerApproved) revert Unauthorized();

        escrow.state = EscrowState.Released;

        uint256 requestId = treasury.requestWithdrawal(escrow.token, escrow.seller, escrow.amount);
        treasury.approveWithdrawal(requestId);

        emit EscrowReleased(_escrowId, escrow.seller);
    }

    function refundToBuyer(uint256 _escrowId) external nonReentrant whenNotPaused {
        EscrowData storage escrow = escrows[_escrowId];
        if (escrow.state != EscrowState.Funded && escrow.state != EscrowState.Disputed) revert InvalidState();

        bool isMediator = msg.sender == escrow.mediator && escrow.mediator != address(0);
        bool canRefund = isMediator || block.timestamp > escrow.deadline;

        if (!canRefund) revert Unauthorized();

        escrow.state = EscrowState.Refunded;

        uint256 requestId = treasury.requestWithdrawal(escrow.token, escrow.buyer, escrow.amount);
        treasury.approveWithdrawal(requestId);

        emit EscrowRefunded(_escrowId, escrow.buyer);
    }

    function disputeEscrow(uint256 _escrowId) external {
        EscrowData storage escrow = escrows[_escrowId];
        if (escrow.state != EscrowState.Funded) revert InvalidState();
        if (msg.sender != escrow.buyer && msg.sender != escrow.seller) revert Unauthorized();
        if (escrow.mediator == address(0)) revert Unauthorized();

        escrow.state = EscrowState.Disputed;
        emit EscrowDisputed(_escrowId, msg.sender);
    }

    function cancelEscrow(uint256 _escrowId) external {
        EscrowData storage escrow = escrows[_escrowId];
        if (escrow.state != EscrowState.Created) revert InvalidState();
        if (msg.sender != escrow.buyer) revert Unauthorized();

        escrow.state = EscrowState.Cancelled;
        emit EscrowCancelled(_escrowId);
    }

    function getEscrow(uint256 _escrowId) external view returns (EscrowData memory) {
        return escrows[_escrowId];
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    uint256[50] private __gap;
}
