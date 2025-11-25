// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract BasePay is Initializable, UUPSUpgradeable, OwnableUpgradeable {
    address public paymentTracker;
    address public escrowContract;

    mapping(bytes32 => bool) public processedPayments;
    mapping(bytes32 => uint256) public paymentAmounts;

    event PaymentReceived(bytes32 indexed paymentId, address indexed payer, uint256 amount);
    event PaymentProcessed(bytes32 indexed paymentId, uint256 escrowId);

    error InvalidTracker();
    error InvalidEscrowContract();
    error AlreadyProcessed();
    error Unauthorized();

    function initialize(address _owner) public initializer {
        __Ownable_init(_owner);
    }

    function setPaymentTracker(address _tracker) external onlyOwner {
        if (_tracker == address(0)) revert InvalidTracker();
        paymentTracker = _tracker;
    }

    function setEscrowContract(address _escrow) external onlyOwner {
        if (_escrow == address(0)) revert InvalidEscrowContract();
        escrowContract = _escrow;
    }

    function receivePayment(bytes32 _paymentId, address _payer, uint256 _amount) external payable {
        if (msg.sender != paymentTracker) revert Unauthorized();
        if (processedPayments[_paymentId]) revert AlreadyProcessed();

        paymentAmounts[_paymentId] = _amount;
        emit PaymentReceived(_paymentId, _payer, _amount);
    }

    function processPayment(bytes32 _paymentId, uint256 _escrowId) external {
        if (msg.sender != escrowContract) revert Unauthorized();
        if (processedPayments[_paymentId]) revert AlreadyProcessed();

        processedPayments[_paymentId] = true;
        emit PaymentProcessed(_paymentId, _escrowId);
    }

    function getPaymentAmount(bytes32 _paymentId) external view returns (uint256) {
        return paymentAmounts[_paymentId];
    }

    function isPaymentProcessed(bytes32 _paymentId) external view returns (bool) {
        return processedPayments[_paymentId];
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    uint256[50] private __gap;
}
