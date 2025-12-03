// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Test} from "forge-std/Test.sol";
import {RulesEngineV1} from "../src/escrow/RulesEngineV1.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {MockVerifier} from "./mocks/MockVerifier.sol";

contract RulesEngineV1Test is Test {
    RulesEngineV1 public rulesEngine;
    MockVerifier public verifier;

    address public owner = address(1);

    event RuleSetCreated(uint256 indexed ruleSetId);
    event RuleSetUpdated(uint256 indexed ruleSetId);
    event DefaultRuleSetChanged(uint256 indexed ruleSetId);

    function setUp() public {
        verifier = new MockVerifier();

        RulesEngineV1 rulesEngineImpl = new RulesEngineV1();
        bytes memory rulesEngineData = abi.encodeWithSelector(
            RulesEngineV1.initialize.selector,
            owner
        );
        ERC1967Proxy rulesEngineProxy = new ERC1967Proxy(address(rulesEngineImpl), rulesEngineData);
        rulesEngine = RulesEngineV1(address(rulesEngineProxy));
    }

    function testInitialize() public view {
        assertEq(rulesEngine.owner(), owner);
    }

    function testCreateRuleSet() public {
        vm.prank(owner);

        uint256 ruleSetId = rulesEngine.createRuleSet(
            true,
            true,
            true,
            true,
            true,
            false,
            address(0)
        );

        assertTrue(ruleSetId != 0);

        RulesEngineV1.RuleSet memory ruleSet = rulesEngine.getRuleSet(ruleSetId);
        assertTrue(ruleSet.requireBuyerApproval);
        assertTrue(ruleSet.requireSellerApproval);
        assertTrue(ruleSet.autoRefundAfterDeadline);
        assertTrue(ruleSet.autoReleaseOnFullApproval);
        assertTrue(ruleSet.mediatorOverrideEnabled);
        assertFalse(ruleSet.externalVerifierEnabled);
        assertEq(ruleSet.externalVerifier, address(0));
    }

    function testCreateRuleSetOnlyOwner() public {
        vm.prank(address(99));
        vm.expectRevert();
        rulesEngine.createRuleSet(
            true,
            true,
            true,
            true,
            true,
            false,
            address(0)
        );
    }

    function testSetDefaultRuleSet() public {
        vm.prank(owner);
        uint256 ruleSetId = rulesEngine.createRuleSet(
            true,
            true,
            true,
            true,
            true,
            false,
            address(0)
        );

        vm.expectEmit(true, false, false, false);
        emit DefaultRuleSetChanged(ruleSetId);

        vm.prank(owner);
        rulesEngine.setDefaultRuleSet(ruleSetId);

        assertEq(rulesEngine.defaultRuleSetId(), ruleSetId);
    }

    function testSetDefaultRuleSetInvalid() public {
        vm.prank(owner);
        uint256 ruleSetId = rulesEngine.createRuleSet(
            false,
            false,
            true,
            true,
            true,
            false,
            address(0)
        );

        vm.prank(owner);
        vm.expectRevert(RulesEngineV1.InvalidRuleSet.selector);
        rulesEngine.setDefaultRuleSet(ruleSetId);
    }

    function testCanReleaseWithBuyerApproval() public {
        vm.prank(owner);
        uint256 ruleSetId = rulesEngine.createRuleSet(
            true,
            false,
            false,
            false,
            false,
            false,
            address(0)
        );

        bool canRelease = rulesEngine.canRelease(
            ruleSetId,
            true,
            false,
            false,
            1,
            ""
        );

        assertTrue(canRelease);

        canRelease = rulesEngine.canRelease(
            ruleSetId,
            false,
            false,
            false,
            1,
            ""
        );

        assertFalse(canRelease);
    }

    function testCanReleaseWithSellerApproval() public {
        vm.prank(owner);
        uint256 ruleSetId = rulesEngine.createRuleSet(
            false,
            true,
            false,
            false,
            false,
            false,
            address(0)
        );

        bool canRelease = rulesEngine.canRelease(
            ruleSetId,
            false,
            true,
            false,
            1,
            ""
        );

        assertTrue(canRelease);

        canRelease = rulesEngine.canRelease(
            ruleSetId,
            false,
            false,
            false,
            1,
            ""
        );

        assertFalse(canRelease);
    }

    function testCanReleaseMediatorOverride() public {
        vm.prank(owner);
        uint256 ruleSetId = rulesEngine.createRuleSet(
            true,
            true,
            false,
            false,
            true,
            false,
            address(0)
        );

        bool canRelease = rulesEngine.canRelease(
            ruleSetId,
            false,
            false,
            true,
            1,
            ""
        );

        assertTrue(canRelease);
    }

    function testCanReleaseExternalVerifier() public {
        vm.prank(owner);
        uint256 ruleSetId = rulesEngine.createRuleSet(
            false,
            false,
            false,
            false,
            false,
            true,
            address(verifier)
        );

        verifier.setVerificationResult(1, true);

        bool canRelease = rulesEngine.canRelease(
            ruleSetId,
            false,
            false,
            false,
            1,
            ""
        );

        assertTrue(canRelease);

        verifier.setVerificationResult(1, false);

        canRelease = rulesEngine.canRelease(
            ruleSetId,
            false,
            false,
            false,
            1,
            ""
        );

        assertFalse(canRelease);
    }

    function testCanReleaseAutoRelease() public {
        vm.prank(owner);
        uint256 ruleSetId = rulesEngine.createRuleSet(
            false,
            false,
            false,
            true,
            false,
            false,
            address(0)
        );

        bool canRelease = rulesEngine.canRelease(
            ruleSetId,
            true,
            true,
            false,
            1,
            ""
        );

        assertTrue(canRelease);

        canRelease = rulesEngine.canRelease(
            ruleSetId,
            false,
            false,
            false,
            1,
            ""
        );

        assertFalse(canRelease);
    }

    function testCanRefundAfterDeadline() public {
        vm.prank(owner);
        uint256 ruleSetId = rulesEngine.createRuleSet(
            false,
            false,
            true,
            false,
            false,
            false,
            address(0)
        );

        uint256 deadline = block.timestamp + 1 days;

        bool canRefund = rulesEngine.canRefund(
            ruleSetId,
            deadline,
            false
        );

        assertFalse(canRefund);

        vm.warp(block.timestamp + 2 days);

        canRefund = rulesEngine.canRefund(
            ruleSetId,
            deadline,
            false
        );

        assertTrue(canRefund);
    }

    function testCanRefundMediatorOverride() public {
        vm.prank(owner);
        uint256 ruleSetId = rulesEngine.createRuleSet(
            false,
            false,
            false,
            false,
            true,
            false,
            address(0)
        );

        bool canRefund = rulesEngine.canRefund(
            ruleSetId,
            block.timestamp + 1 days,
            true
        );

        assertTrue(canRefund);
    }
}
