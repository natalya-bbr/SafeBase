// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Test} from "forge-std/Test.sol";
import {SafeBaseEscrowV1} from "../src/escrow/SafeBaseEscrowV1.sol";
import {RulesEngineV1} from "../src/escrow/RulesEngineV1.sol";
import {Treasury} from "../src/Treasury.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract SafeBaseEscrowRulesIntegrationTest is Test {
    SafeBaseEscrowV1 public escrow;
    RulesEngineV1 public rulesEngine;
    Treasury public treasury;

    address public owner = address(1);
    address public buyer = address(2);
    address public seller = address(3);
    address public mediator = address(4);

    uint256 public ruleSetId;

    event EscrowCreated(
        uint256 indexed escrowId,
        address indexed buyer,
        address indexed seller,
        address token,
        uint256 amount,
        uint256 deadline
    );
    event EscrowReleased(uint256 indexed escrowId, address indexed recipient);
    event EscrowRefunded(uint256 indexed escrowId, address indexed recipient);

    function setUp() public {
        Treasury treasuryImpl = new Treasury();
        bytes memory treasuryData = abi.encodeWithSelector(
            Treasury.initialize.selector,
            owner,
            1
        );
        ERC1967Proxy treasuryProxy = new ERC1967Proxy(address(treasuryImpl), treasuryData);
        treasury = Treasury(payable(address(treasuryProxy)));

        SafeBaseEscrowV1 escrowImpl = new SafeBaseEscrowV1();
        bytes memory escrowData = abi.encodeWithSelector(
            SafeBaseEscrowV1.initialize.selector,
            owner,
            address(treasury)
        );
        ERC1967Proxy escrowProxy = new ERC1967Proxy(address(escrowImpl), escrowData);
        escrow = SafeBaseEscrowV1(address(escrowProxy));

        RulesEngineV1 rulesEngineImpl = new RulesEngineV1();
        bytes memory rulesEngineData = abi.encodeWithSelector(
            RulesEngineV1.initialize.selector,
            owner
        );
        ERC1967Proxy rulesEngineProxy = new ERC1967Proxy(address(rulesEngineImpl), rulesEngineData);
        rulesEngine = RulesEngineV1(address(rulesEngineProxy));

        vm.startPrank(owner);
        treasury.addAdmin(address(escrow));
        treasury.addExecutor(address(escrow));
        escrow.setRulesEngine(address(rulesEngine));

        ruleSetId = rulesEngine.createRuleSet(
            true,
            false,
            true,
            false,
            true,
            false,
            address(0)
        );
        vm.stopPrank();

        vm.deal(buyer, 100 ether);
    }

    function testReleaseWithRulesEngineApproval() public {
        vm.prank(buyer);
        uint256 escrowId = escrow.createEscrow(
            seller,
            mediator,
            address(0),
            1 ether,
            block.timestamp + 1 days,
            ruleSetId
        );

        vm.prank(buyer);
        escrow.fundEscrow{value: 1 ether}(escrowId);

        vm.prank(buyer);
        escrow.approveBuyer(escrowId);

        uint256 sellerBalanceBefore = seller.balance;

        vm.prank(buyer);
        escrow.releaseToSeller(escrowId);

        SafeBaseEscrowV1.EscrowData memory escrowData = escrow.getEscrow(escrowId);
        assertTrue(escrowData.state == SafeBaseEscrowV1.EscrowState.Released);
        assertEq(seller.balance, sellerBalanceBefore + 1 ether);
    }

    function testReleaseWithRulesEngineRejection() public {
        vm.prank(buyer);
        uint256 escrowId = escrow.createEscrow(
            seller,
            mediator,
            address(0),
            1 ether,
            block.timestamp + 1 days,
            ruleSetId
        );

        vm.prank(buyer);
        escrow.fundEscrow{value: 1 ether}(escrowId);

        vm.prank(buyer);
        vm.expectRevert(SafeBaseEscrowV1.Unauthorized.selector);
        escrow.releaseToSeller(escrowId);
    }

    function testReleaseWithMediatorOverride() public {
        vm.prank(buyer);
        uint256 escrowId = escrow.createEscrow(
            seller,
            mediator,
            address(0),
            1 ether,
            block.timestamp + 1 days,
            ruleSetId
        );

        vm.prank(buyer);
        escrow.fundEscrow{value: 1 ether}(escrowId);

        uint256 sellerBalanceBefore = seller.balance;

        vm.prank(mediator);
        escrow.releaseToSeller(escrowId);

        SafeBaseEscrowV1.EscrowData memory escrowData = escrow.getEscrow(escrowId);
        assertTrue(escrowData.state == SafeBaseEscrowV1.EscrowState.Released);
        assertEq(seller.balance, sellerBalanceBefore + 1 ether);
    }

    function testRefundWithRulesEngineAfterDeadline() public {
        vm.prank(buyer);
        uint256 escrowId = escrow.createEscrow(
            seller,
            mediator,
            address(0),
            1 ether,
            block.timestamp + 1 days,
            ruleSetId
        );

        vm.prank(buyer);
        escrow.fundEscrow{value: 1 ether}(escrowId);

        vm.warp(block.timestamp + 2 days);

        uint256 buyerBalanceBefore = buyer.balance;

        vm.prank(buyer);
        escrow.refundToBuyer(escrowId);

        SafeBaseEscrowV1.EscrowData memory escrowData = escrow.getEscrow(escrowId);
        assertTrue(escrowData.state == SafeBaseEscrowV1.EscrowState.Refunded);
        assertEq(buyer.balance, buyerBalanceBefore + 1 ether);
    }

    function testRefundWithRulesEngineBeforeDeadline() public {
        vm.prank(buyer);
        uint256 escrowId = escrow.createEscrow(
            seller,
            mediator,
            address(0),
            1 ether,
            block.timestamp + 1 days,
            ruleSetId
        );

        vm.prank(buyer);
        escrow.fundEscrow{value: 1 ether}(escrowId);

        vm.prank(buyer);
        vm.expectRevert(SafeBaseEscrowV1.Unauthorized.selector);
        escrow.refundToBuyer(escrowId);
    }

    function testRefundWithMediatorOverride() public {
        vm.prank(buyer);
        uint256 escrowId = escrow.createEscrow(
            seller,
            mediator,
            address(0),
            1 ether,
            block.timestamp + 1 days,
            ruleSetId
        );

        vm.prank(buyer);
        escrow.fundEscrow{value: 1 ether}(escrowId);

        uint256 buyerBalanceBefore = buyer.balance;

        vm.prank(mediator);
        escrow.refundToBuyer(escrowId);

        SafeBaseEscrowV1.EscrowData memory escrowData = escrow.getEscrow(escrowId);
        assertTrue(escrowData.state == SafeBaseEscrowV1.EscrowState.Refunded);
        assertEq(buyer.balance, buyerBalanceBefore + 1 ether);
    }

    function testDisputedToReleasedWithRulesEngine() public {
        vm.prank(buyer);
        uint256 escrowId = escrow.createEscrow(
            seller,
            mediator,
            address(0),
            1 ether,
            block.timestamp + 1 days,
            ruleSetId
        );

        vm.prank(buyer);
        escrow.fundEscrow{value: 1 ether}(escrowId);

        vm.prank(buyer);
        escrow.disputeEscrow(escrowId);

        SafeBaseEscrowV1.EscrowData memory escrowData = escrow.getEscrow(escrowId);
        assertTrue(escrowData.state == SafeBaseEscrowV1.EscrowState.Disputed);

        uint256 sellerBalanceBefore = seller.balance;

        vm.prank(mediator);
        escrow.releaseToSeller(escrowId);

        escrowData = escrow.getEscrow(escrowId);
        assertTrue(escrowData.state == SafeBaseEscrowV1.EscrowState.Released);
        assertEq(seller.balance, sellerBalanceBefore + 1 ether);
    }

    function testDisputedToRefundedWithRulesEngine() public {
        vm.prank(buyer);
        uint256 escrowId = escrow.createEscrow(
            seller,
            mediator,
            address(0),
            1 ether,
            block.timestamp + 1 days,
            ruleSetId
        );

        vm.prank(buyer);
        escrow.fundEscrow{value: 1 ether}(escrowId);

        vm.prank(buyer);
        escrow.disputeEscrow(escrowId);

        SafeBaseEscrowV1.EscrowData memory escrowData = escrow.getEscrow(escrowId);
        assertTrue(escrowData.state == SafeBaseEscrowV1.EscrowState.Disputed);

        uint256 buyerBalanceBefore = buyer.balance;

        vm.prank(mediator);
        escrow.refundToBuyer(escrowId);

        escrowData = escrow.getEscrow(escrowId);
        assertTrue(escrowData.state == SafeBaseEscrowV1.EscrowState.Refunded);
        assertEq(buyer.balance, buyerBalanceBefore + 1 ether);
    }

    function testEscrowWithoutRulesEngineWorks() public {
        vm.prank(buyer);
        uint256 escrowId = escrow.createEscrow(
            seller,
            mediator,
            address(0),
            1 ether,
            block.timestamp + 1 days,
            0
        );

        vm.prank(buyer);
        escrow.fundEscrow{value: 1 ether}(escrowId);

        vm.prank(buyer);
        escrow.approveBuyer(escrowId);

        uint256 sellerBalanceBefore = seller.balance;

        vm.prank(buyer);
        escrow.releaseToSeller(escrowId);

        SafeBaseEscrowV1.EscrowData memory escrowData = escrow.getEscrow(escrowId);
        assertTrue(escrowData.state == SafeBaseEscrowV1.EscrowState.Released);
        assertEq(seller.balance, sellerBalanceBefore + 1 ether);
    }

    receive() external payable {}
}
