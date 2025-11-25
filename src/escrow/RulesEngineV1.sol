// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

interface IVerifier {
    function verify(uint256 escrowId, bytes calldata data) external view returns (bool);
}

contract RulesEngineV1 is Initializable, UUPSUpgradeable, OwnableUpgradeable {
    struct RuleSet {
        bool requireBuyerApproval;
        bool requireSellerApproval;
        bool autoRefundAfterDeadline;
        bool autoReleaseOnFullApproval;
        bool mediatorOverrideEnabled;
        bool externalVerifierEnabled;
        address externalVerifier;
    }

    mapping(uint256 => RuleSet) public ruleSets;
    uint256 public defaultRuleSetId;

    event RuleSetCreated(uint256 indexed ruleSetId);
    event RuleSetUpdated(uint256 indexed ruleSetId);
    event DefaultRuleSetChanged(uint256 indexed ruleSetId);

    error InvalidRuleSet();
    error InvalidVerifier();

    function initialize(address _owner) public initializer {
        __Ownable_init(_owner);
    }

    function createRuleSet(
        bool _requireBuyerApproval,
        bool _requireSellerApproval,
        bool _autoRefundAfterDeadline,
        bool _autoReleaseOnFullApproval,
        bool _mediatorOverrideEnabled,
        bool _externalVerifierEnabled,
        address _externalVerifier
    ) external onlyOwner returns (uint256) {
        uint256 ruleSetId = uint256(
            keccak256(
                abi.encodePacked(
                    _requireBuyerApproval,
                    _requireSellerApproval,
                    _autoRefundAfterDeadline,
                    _autoReleaseOnFullApproval,
                    _mediatorOverrideEnabled,
                    block.timestamp
                )
            )
        );

        ruleSets[ruleSetId] = RuleSet({
            requireBuyerApproval: _requireBuyerApproval,
            requireSellerApproval: _requireSellerApproval,
            autoRefundAfterDeadline: _autoRefundAfterDeadline,
            autoReleaseOnFullApproval: _autoReleaseOnFullApproval,
            mediatorOverrideEnabled: _mediatorOverrideEnabled,
            externalVerifierEnabled: _externalVerifierEnabled,
            externalVerifier: _externalVerifier
        });

        emit RuleSetCreated(ruleSetId);
        return ruleSetId;
    }

    function setDefaultRuleSet(uint256 _ruleSetId) external onlyOwner {
        if (ruleSets[_ruleSetId].requireBuyerApproval == false &&
            ruleSets[_ruleSetId].requireSellerApproval == false) {
            revert InvalidRuleSet();
        }
        defaultRuleSetId = _ruleSetId;
        emit DefaultRuleSetChanged(_ruleSetId);
    }

    function canRelease(
        uint256 _ruleSetId,
        bool _buyerApproved,
        bool _sellerApproved,
        bool _isMediatorOverride,
        uint256 _escrowId,
        bytes calldata _verifierData
    ) external view returns (bool) {
        RuleSet memory rules = ruleSets[_ruleSetId];

        if (_isMediatorOverride && rules.mediatorOverrideEnabled) {
            return true;
        }

        if (rules.requireBuyerApproval && !_buyerApproved) {
            return false;
        }

        if (rules.requireSellerApproval && !_sellerApproved) {
            return false;
        }

        if (rules.externalVerifierEnabled) {
            if (rules.externalVerifier == address(0)) return false;
            return IVerifier(rules.externalVerifier).verify(_escrowId, _verifierData);
        }

        if (rules.autoReleaseOnFullApproval && _buyerApproved && _sellerApproved) {
            return true;
        }

        return _buyerApproved || _sellerApproved;
    }

    function canRefund(
        uint256 _ruleSetId,
        uint256 _deadline,
        bool _isMediatorOverride
    ) external view returns (bool) {
        RuleSet memory rules = ruleSets[_ruleSetId];

        if (_isMediatorOverride && rules.mediatorOverrideEnabled) {
            return true;
        }

        if (rules.autoRefundAfterDeadline && block.timestamp > _deadline) {
            return true;
        }

        return false;
    }

    function getRuleSet(uint256 _ruleSetId) external view returns (RuleSet memory) {
        return ruleSets[_ruleSetId];
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    uint256[50] private __gap;
}
