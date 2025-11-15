// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {IERC20} from "./IERC20.sol";

contract Treasury is Initializable, UUPSUpgradeable, OwnableUpgradeable {

    enum RequestStatus { Pending, Approved, Executed, Cancelled }

    struct WithdrawalRequest {
        address token;
        address to;
        uint256 amount;
        uint256 approvalCount;
        RequestStatus status;
        mapping(address => bool) approvals;
    }

    uint256 private constant MAX_ADMINS = 10;

    mapping(address => bool) public admins;
    mapping(address => bool) public executors;
    mapping(uint256 => WithdrawalRequest) public requests;

    uint256 public adminCount;
    uint256 public requestCount;
    uint256 public requiredApprovals;

    event AdminAdded(address indexed admin);
    event AdminRemoved(address indexed admin);
    event ExecutorAdded(address indexed executor);
    event ExecutorRemoved(address indexed executor);
    event Deposited(address indexed from, uint256 amount);
    event WithdrawalRequested(uint256 indexed requestId, address token, address to, uint256 amount);
    event WithdrawalApproved(uint256 indexed requestId, address indexed admin);
    event WithdrawalExecuted(uint256 indexed requestId);
    event WithdrawalCancelled(uint256 indexed requestId);

    error MaxAdminsReached();
    error AlreadyAdmin();
    error NotAdmin();
    error AlreadyExecutor();
    error NotExecutor();
    error ZeroAddress();
    error InvalidRequest();
    error AlreadyApproved();
    error InsufficientApprovals();
    error InvalidStatus();
    error ZeroAmount();
    error InsufficientBalance();
    error TransferFailed();

    modifier onlyAdmin() {
        if (!admins[msg.sender] && owner() != msg.sender) revert NotAdmin();
        _;
    }

    modifier onlyExecutor() {
        if (!executors[msg.sender]) revert NotExecutor();
        _;
    }

    function initialize(address _owner, uint256 _requiredApprovals) public initializer {
        __Ownable_init(_owner);
        requiredApprovals = _requiredApprovals;
    }

    function addAdmin(address admin) external onlyOwner {
        if (admin == address(0)) revert ZeroAddress();
        if (admins[admin]) revert AlreadyAdmin();
        if (adminCount >= MAX_ADMINS) revert MaxAdminsReached();

        admins[admin] = true;
        adminCount++;
        emit AdminAdded(admin);
    }

    function removeAdmin(address admin) external onlyOwner {
        if (!admins[admin]) revert NotAdmin();

        admins[admin] = false;
        adminCount--;
        emit AdminRemoved(admin);
    }

    function addExecutor(address executor) external onlyOwner {
        if (executor == address(0)) revert ZeroAddress();
        if (executors[executor]) revert AlreadyExecutor();

        executors[executor] = true;
        emit ExecutorAdded(executor);
    }

    function removeExecutor(address executor) external onlyOwner {
        if (!executors[executor]) revert NotExecutor();

        executors[executor] = false;
        emit ExecutorRemoved(executor);
    }

    function requestWithdrawal(
        address token,
        address to,
        uint256 amount
    ) external onlyAdmin returns (uint256) {
        if (to == address(0)) revert ZeroAddress();
        if (amount == 0) revert ZeroAmount();

        uint256 balance = token == address(0)
            ? address(this).balance
            : IERC20(token).balanceOf(address(this));

        if (balance < amount) revert InsufficientBalance();

        uint256 requestId = requestCount++;
        WithdrawalRequest storage request = requests[requestId];
        request.token = token;
        request.to = to;
        request.amount = amount;
        request.status = RequestStatus.Pending;

        emit WithdrawalRequested(requestId, token, to, amount);
        return requestId;
    }

    function approveWithdrawal(uint256 requestId) external onlyAdmin {
        WithdrawalRequest storage request = requests[requestId];
        if (request.status != RequestStatus.Pending) revert InvalidStatus();
        if (request.approvals[msg.sender]) revert AlreadyApproved();

        request.approvals[msg.sender] = true;
        request.approvalCount++;

        if (request.approvalCount >= requiredApprovals) {
            request.status = RequestStatus.Approved;
        }

        emit WithdrawalApproved(requestId, msg.sender);
    }

    function executeWithdrawal(uint256 requestId) external onlyExecutor {
        WithdrawalRequest storage request = requests[requestId];
        if (request.status != RequestStatus.Approved) revert InvalidStatus();
        if (request.approvalCount < requiredApprovals) revert InsufficientApprovals();

        request.status = RequestStatus.Executed;

        if (request.token == address(0)) {
            (bool success,) = request.to.call{value: request.amount}("");
            if (!success) revert TransferFailed();
        } else {
            IERC20(request.token).transfer(request.to, request.amount);
        }

        emit WithdrawalExecuted(requestId);
    }

    function cancelWithdrawal(uint256 requestId) external onlyAdmin {
        WithdrawalRequest storage request = requests[requestId];
        if (request.status == RequestStatus.Executed) revert InvalidStatus();
        request.status = RequestStatus.Cancelled;
        emit WithdrawalCancelled(requestId);
    }

    function setRequiredApprovals(uint256 _requiredApprovals) external onlyOwner {
        require(_requiredApprovals > 0, "Invalid approval count");
        requiredApprovals = _requiredApprovals;
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    receive() external payable {
        emit Deposited(msg.sender, msg.value);
    }
}
