// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract PaymentTracker is Initializable, UUPSUpgradeable, OwnableUpgradeable {
    mapping(bytes32 => uint256) public paymentIdToEscrow;
    mapping(uint256 => bytes32) public escrowToPaymentId;
    mapping(bytes32 => address) public paymentIdToPayer;

    event PaymentLinked(bytes32 indexed paymentId, uint256 indexed escrowId, address indexed payer);

    error InvalidPaymentId();
    error InvalidEscrowId();
    error AlreadyLinked();

    function initialize(address _owner) public initializer {
        __Ownable_init(_owner);
    }

    function linkPayment(bytes32 _paymentId, uint256 _escrowId, address _payer) external {
        if (_paymentId == bytes32(0)) revert InvalidPaymentId();
        if (_escrowId == 0) revert InvalidEscrowId();
        if (paymentIdToEscrow[_paymentId] != 0) revert AlreadyLinked();

        paymentIdToEscrow[_paymentId] = _escrowId;
        escrowToPaymentId[_escrowId] = _paymentId;
        paymentIdToPayer[_paymentId] = _payer;

        emit PaymentLinked(_paymentId, _escrowId, _payer);
    }

    function getEscrowForPayment(bytes32 _paymentId) external view returns (uint256) {
        return paymentIdToEscrow[_paymentId];
    }

    function getPaymentForEscrow(uint256 _escrowId) external view returns (bytes32) {
        return escrowToPaymentId[_escrowId];
    }

    function getPayerForPayment(bytes32 _paymentId) external view returns (address) {
        return paymentIdToPayer[_paymentId];
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    uint256[50] private __gap;
}
