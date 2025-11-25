// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

interface ISafeBaseEscrow {
    function getEscrow(uint256 escrowId) external view returns (
        address buyer,
        address seller,
        address mediator,
        address token,
        uint256 amount,
        uint256 deadline,
        uint8 state,
        bool buyerApproved,
        bool sellerApproved,
        bytes32 paymentId,
        uint256 createdAt
    );
    function refundToBuyer(uint256 escrowId) external;
    function releaseToSeller(uint256 escrowId) external;
}

interface IRulesEngine {
    function canRelease(
        uint256 ruleSetId,
        bool buyerApproved,
        bool sellerApproved,
        bool isMediatorOverride,
        uint256 escrowId,
        bytes calldata verifierData
    ) external view returns (bool);

    function canRefund(
        uint256 ruleSetId,
        uint256 deadline,
        bool isMediatorOverride
    ) external view returns (bool);
}

contract ExecutorV1 is Initializable, UUPSUpgradeable, OwnableUpgradeable {
    ISafeBaseEscrow public escrowContract;
    IRulesEngine public rulesEngine;

    mapping(uint256 => bool) public scheduledForRefund;
    mapping(uint256 => bool) public scheduledForRelease;
    mapping(address => bool) public automators;

    event DeadlineCheckScheduled(uint256 indexed escrowId, uint256 deadline);
    event AutoRefundExecuted(uint256 indexed escrowId);
    event AutoReleaseExecuted(uint256 indexed escrowId);
    event AutomatorAdded(address indexed automator);
    event AutomatorRemoved(address indexed automator);

    error Unauthorized();
    error InvalidContract();
    error DeadlineNotReached();
    error InvalidState();

    modifier onlyAutomator() {
        if (!automators[msg.sender] && msg.sender != owner()) revert Unauthorized();
        _;
    }

    function initialize(address _owner, address _escrowContract, address _rulesEngine) public initializer {
        __Ownable_init(_owner);

        if (_escrowContract == address(0) || _rulesEngine == address(0)) revert InvalidContract();

        escrowContract = ISafeBaseEscrow(_escrowContract);
        rulesEngine = IRulesEngine(_rulesEngine);
    }

    function addAutomator(address _automator) external onlyOwner {
        automators[_automator] = true;
        emit AutomatorAdded(_automator);
    }

    function removeAutomator(address _automator) external onlyOwner {
        automators[_automator] = false;
        emit AutomatorRemoved(_automator);
    }

    function scheduleDeadlineCheck(uint256 _escrowId, uint256 _deadline) external onlyAutomator {
        scheduledForRefund[_escrowId] = true;
        emit DeadlineCheckScheduled(_escrowId, _deadline);
    }

    function executeAutoRefund(uint256 _escrowId, uint256 _ruleSetId) external onlyAutomator {
        (
            ,
            ,
            ,
            ,
            ,
            uint256 deadline,
            uint8 state,
            ,
            ,
            ,
        ) = escrowContract.getEscrow(_escrowId);

        if (state != 1) revert InvalidState();

        bool canRefund = rulesEngine.canRefund(_ruleSetId, deadline, false);
        if (!canRefund) revert DeadlineNotReached();

        escrowContract.refundToBuyer(_escrowId);
        scheduledForRefund[_escrowId] = false;

        emit AutoRefundExecuted(_escrowId);
    }

    function executeAutoRelease(uint256 _escrowId, uint256 _ruleSetId) external onlyAutomator {
        (
            ,
            ,
            ,
            ,
            ,
            ,
            uint8 state,
            bool buyerApproved,
            bool sellerApproved,
            ,
        ) = escrowContract.getEscrow(_escrowId);

        if (state != 1) revert InvalidState();

        bool canRelease = rulesEngine.canRelease(
            _ruleSetId,
            buyerApproved,
            sellerApproved,
            false,
            _escrowId,
            ""
        );

        if (!canRelease) revert Unauthorized();

        escrowContract.releaseToSeller(_escrowId);
        scheduledForRelease[_escrowId] = false;

        emit AutoReleaseExecuted(_escrowId);
    }

    function checkAndExecuteDeadlines(uint256[] calldata _escrowIds, uint256 _ruleSetId) external onlyAutomator {
        for (uint256 i = 0; i < _escrowIds.length; i++) {
            uint256 escrowId = _escrowIds[i];

            (
                ,
                ,
                ,
                ,
                ,
                uint256 deadline,
                uint8 state,
                ,
                ,
                ,
            ) = escrowContract.getEscrow(escrowId);

            if (state == 1 && block.timestamp > deadline) {
                bool canRefund = rulesEngine.canRefund(_ruleSetId, deadline, false);
                if (canRefund) {
                    try escrowContract.refundToBuyer(escrowId) {
                        emit AutoRefundExecuted(escrowId);
                    } catch {}
                }
            }
        }
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    uint256[50] private __gap;
}
