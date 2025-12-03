// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Test} from "forge-std/Test.sol";
import {SafeBaseEscrowV1} from "../src/escrow/SafeBaseEscrowV1.sol";
import {Treasury} from "../src/Treasury.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {MockERC20} from "./mocks/MockERC20.sol";

contract SafeBaseEscrowV1Test is Test {
    SafeBaseEscrowV1 public escrow;
    Treasury public treasury;
    MockERC20 public token;

    address public owner = address(1);
    address public buyer = address(2);
    address public seller = address(3);
    address public mediator = address(4);

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
    event ApprovalGranted(uint256 indexed escrowId, address indexed party);
    event BasePayFundingReceived(uint256 indexed escrowId, bytes32 indexed paymentId);

    function setUp() public {
        token = new MockERC20("Test Token", "TEST", 18);

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

        vm.startPrank(owner);
        treasury.addAdmin(address(escrow));
        treasury.addExecutor(address(escrow));
        vm.stopPrank();

        vm.deal(buyer, 100 ether);
        token.mint(buyer, 1000 ether);
    }

    function testInitialize() public view {
        assertEq(address(escrow.treasury()), address(treasury));
        assertEq(escrow.owner(), owner);
    }

    function testCreateEscrow() public {
        vm.prank(buyer);

        vm.expectEmit(true, true, true, true);
        emit EscrowCreated(1, buyer, seller, address(0), 1 ether, block.timestamp + 1 days);

        uint256 escrowId = escrow.createEscrow(
            seller,
            mediator,
            address(0),
            1 ether,
            block.timestamp + 1 days
        );

        assertEq(escrowId, 1);
        SafeBaseEscrowV1.EscrowData memory escrowData = escrow.getEscrow(escrowId);

        assertEq(escrowData.buyer, buyer);
        assertEq(escrowData.seller, seller);
        assertEq(escrowData.mediator, mediator);
        assertEq(escrowData.token, address(0));
        assertEq(escrowData.amount, 1 ether);
        assertEq(escrowData.deadline, block.timestamp + 1 days);
        assertTrue(escrowData.state == SafeBaseEscrowV1.EscrowState.Created);
    }

    function testCreateEscrowZeroSeller() public {
        vm.prank(buyer);
        vm.expectRevert(SafeBaseEscrowV1.InvalidAddress.selector);
        escrow.createEscrow(
            address(0),
            mediator,
            address(0),
            1 ether,
            block.timestamp + 1 days
        );
    }

    function testCreateEscrowZeroAmount() public {
        vm.prank(buyer);
        vm.expectRevert(SafeBaseEscrowV1.InvalidAmount.selector);
        escrow.createEscrow(
            seller,
            mediator,
            address(0),
            0,
            block.timestamp + 1 days
        );
    }

    function testCreateEscrowPastDeadline() public {
        vm.prank(buyer);
        vm.expectRevert(SafeBaseEscrowV1.DeadlineExpired.selector);
        escrow.createEscrow(
            seller,
            mediator,
            address(0),
            1 ether,
            block.timestamp - 1
        );
    }

    function testFundEscrowETH() public {
        vm.prank(buyer);
        uint256 escrowId = escrow.createEscrow(
            seller,
            mediator,
            address(0),
            1 ether,
            block.timestamp + 1 days
        );

        vm.expectEmit(true, false, false, true);
        emit EscrowFunded(escrowId, 1 ether);

        vm.prank(buyer);
        escrow.fundEscrow{value: 1 ether}(escrowId);

        SafeBaseEscrowV1.EscrowData memory escrowData = escrow.getEscrow(escrowId);
        assertTrue(escrowData.state == SafeBaseEscrowV1.EscrowState.Funded);
    }

    function testFundEscrowNotBuyer() public {
        vm.prank(buyer);
        uint256 escrowId = escrow.createEscrow(
            seller,
            mediator,
            address(0),
            1 ether,
            block.timestamp + 1 days
        );

        vm.deal(seller, 1 ether);
        vm.prank(seller);
        vm.expectRevert(SafeBaseEscrowV1.Unauthorized.selector);
        escrow.fundEscrow{value: 1 ether}(escrowId);
    }

    function testFundEscrowWrongState() public {
        vm.prank(buyer);
        uint256 escrowId = escrow.createEscrow(
            seller,
            mediator,
            address(0),
            1 ether,
            block.timestamp + 1 days
        );

        vm.prank(buyer);
        escrow.fundEscrow{value: 1 ether}(escrowId);

        vm.prank(buyer);
        vm.expectRevert(SafeBaseEscrowV1.InvalidState.selector);
        escrow.fundEscrow{value: 1 ether}(escrowId);
    }

    function testFundEscrowWrongAmount() public {
        vm.prank(buyer);
        uint256 escrowId = escrow.createEscrow(
            seller,
            mediator,
            address(0),
            1 ether,
            block.timestamp + 1 days
        );

        vm.prank(buyer);
        vm.expectRevert(SafeBaseEscrowV1.InvalidAmount.selector);
        escrow.fundEscrow{value: 0.5 ether}(escrowId);
    }

    function testFundEscrowWithBasePay() public {
        vm.prank(buyer);
        uint256 escrowId = escrow.createEscrow(
            seller,
            mediator,
            address(0),
            1 ether,
            block.timestamp + 1 days
        );

        bytes32 paymentId = keccak256("payment1");

        vm.expectEmit(true, false, false, true);
        emit EscrowFunded(escrowId, 1 ether);

        escrow.fundEscrowWithBasePay(escrowId, paymentId);

        SafeBaseEscrowV1.EscrowData memory escrowData = escrow.getEscrow(escrowId);
        assertTrue(escrowData.state == SafeBaseEscrowV1.EscrowState.Funded);
        assertEq(escrowData.paymentId, paymentId);
        assertEq(escrow.paymentIdToEscrow(paymentId), escrowId);
    }

    function testApproveBuyer() public {
        vm.prank(buyer);
        uint256 escrowId = escrow.createEscrow(
            seller,
            mediator,
            address(0),
            1 ether,
            block.timestamp + 1 days
        );

        vm.prank(buyer);
        escrow.fundEscrow{value: 1 ether}(escrowId);

        vm.expectEmit(true, true, false, false);
        emit ApprovalGranted(escrowId, buyer);

        vm.prank(buyer);
        escrow.approveBuyer(escrowId);

        SafeBaseEscrowV1.EscrowData memory escrowData = escrow.getEscrow(escrowId);
        assertTrue(escrowData.buyerApproved);
    }

    function testApproveBuyerUnauthorized() public {
        vm.prank(buyer);
        uint256 escrowId = escrow.createEscrow(
            seller,
            mediator,
            address(0),
            1 ether,
            block.timestamp + 1 days
        );

        vm.prank(buyer);
        escrow.fundEscrow{value: 1 ether}(escrowId);

        vm.prank(seller);
        vm.expectRevert(SafeBaseEscrowV1.Unauthorized.selector);
        escrow.approveBuyer(escrowId);
    }

    function testApproveBuyerAlreadyApproved() public {
        vm.prank(buyer);
        uint256 escrowId = escrow.createEscrow(
            seller,
            mediator,
            address(0),
            1 ether,
            block.timestamp + 1 days
        );

        vm.prank(buyer);
        escrow.fundEscrow{value: 1 ether}(escrowId);

        vm.prank(buyer);
        escrow.approveBuyer(escrowId);

        vm.prank(buyer);
        vm.expectRevert(SafeBaseEscrowV1.AlreadyApproved.selector);
        escrow.approveBuyer(escrowId);
    }

    function testApproveSeller() public {
        vm.prank(buyer);
        uint256 escrowId = escrow.createEscrow(
            seller,
            mediator,
            address(0),
            1 ether,
            block.timestamp + 1 days
        );

        vm.prank(buyer);
        escrow.fundEscrow{value: 1 ether}(escrowId);

        vm.expectEmit(true, true, false, false);
        emit ApprovalGranted(escrowId, seller);

        vm.prank(seller);
        escrow.approveSeller(escrowId);

        SafeBaseEscrowV1.EscrowData memory escrowData = escrow.getEscrow(escrowId);
        assertTrue(escrowData.sellerApproved);
    }

    function testReleaseToSeller() public {
        vm.prank(buyer);
        uint256 escrowId = escrow.createEscrow(
            seller,
            mediator,
            address(0),
            1 ether,
            block.timestamp + 1 days
        );

        vm.prank(buyer);
        escrow.fundEscrow{value: 1 ether}(escrowId);

        vm.prank(buyer);
        escrow.approveBuyer(escrowId);

        uint256 sellerBalanceBefore = seller.balance;

        vm.expectEmit(true, true, false, false);
        emit EscrowReleased(escrowId, seller);

        vm.prank(buyer);
        escrow.releaseToSeller(escrowId);

        SafeBaseEscrowV1.EscrowData memory escrowData = escrow.getEscrow(escrowId);
        assertTrue(escrowData.state == SafeBaseEscrowV1.EscrowState.Released);
        assertEq(seller.balance, sellerBalanceBefore + 1 ether);
    }

    function testReleaseToSellerMediator() public {
        vm.prank(buyer);
        uint256 escrowId = escrow.createEscrow(
            seller,
            mediator,
            address(0),
            1 ether,
            block.timestamp + 1 days
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

    function testReleaseToSellerUnauthorized() public {
        vm.prank(buyer);
        uint256 escrowId = escrow.createEscrow(
            seller,
            mediator,
            address(0),
            1 ether,
            block.timestamp + 1 days
        );

        vm.prank(buyer);
        escrow.fundEscrow{value: 1 ether}(escrowId);

        vm.prank(seller);
        vm.expectRevert(SafeBaseEscrowV1.Unauthorized.selector);
        escrow.releaseToSeller(escrowId);
    }

    function testRefundToBuyer() public {
        vm.prank(buyer);
        uint256 escrowId = escrow.createEscrow(
            seller,
            mediator,
            address(0),
            1 ether,
            block.timestamp + 1 days
        );

        vm.prank(buyer);
        escrow.fundEscrow{value: 1 ether}(escrowId);

        vm.warp(block.timestamp + 2 days);

        uint256 buyerBalanceBefore = buyer.balance;

        vm.expectEmit(true, true, false, false);
        emit EscrowRefunded(escrowId, buyer);

        vm.prank(buyer);
        escrow.refundToBuyer(escrowId);

        SafeBaseEscrowV1.EscrowData memory escrowData = escrow.getEscrow(escrowId);
        assertTrue(escrowData.state == SafeBaseEscrowV1.EscrowState.Refunded);
        assertEq(buyer.balance, buyerBalanceBefore + 1 ether);
    }

    function testRefundToBuyerMediator() public {
        vm.prank(buyer);
        uint256 escrowId = escrow.createEscrow(
            seller,
            mediator,
            address(0),
            1 ether,
            block.timestamp + 1 days
        );

        vm.prank(buyer);
        escrow.fundEscrow{value: 1 ether}(escrowId);

        vm.prank(buyer);
        escrow.disputeEscrow(escrowId);

        uint256 buyerBalanceBefore = buyer.balance;

        vm.prank(mediator);
        escrow.refundToBuyer(escrowId);

        SafeBaseEscrowV1.EscrowData memory escrowData = escrow.getEscrow(escrowId);
        assertTrue(escrowData.state == SafeBaseEscrowV1.EscrowState.Refunded);
        assertEq(buyer.balance, buyerBalanceBefore + 1 ether);
    }

    function testRefundToBuyerBeforeDeadline() public {
        vm.prank(buyer);
        uint256 escrowId = escrow.createEscrow(
            seller,
            mediator,
            address(0),
            1 ether,
            block.timestamp + 1 days
        );

        vm.prank(buyer);
        escrow.fundEscrow{value: 1 ether}(escrowId);

        vm.prank(buyer);
        vm.expectRevert(SafeBaseEscrowV1.Unauthorized.selector);
        escrow.refundToBuyer(escrowId);
    }

    function testDisputeEscrow() public {
        vm.prank(buyer);
        uint256 escrowId = escrow.createEscrow(
            seller,
            mediator,
            address(0),
            1 ether,
            block.timestamp + 1 days
        );

        vm.prank(buyer);
        escrow.fundEscrow{value: 1 ether}(escrowId);

        vm.expectEmit(true, true, false, false);
        emit EscrowDisputed(escrowId, buyer);

        vm.prank(buyer);
        escrow.disputeEscrow(escrowId);

        SafeBaseEscrowV1.EscrowData memory escrowData = escrow.getEscrow(escrowId);
        assertTrue(escrowData.state == SafeBaseEscrowV1.EscrowState.Disputed);
    }

    function testDisputeEscrowNoMediator() public {
        vm.prank(buyer);
        uint256 escrowId = escrow.createEscrow(
            seller,
            address(0),
            address(0),
            1 ether,
            block.timestamp + 1 days
        );

        vm.prank(buyer);
        escrow.fundEscrow{value: 1 ether}(escrowId);

        vm.prank(buyer);
        vm.expectRevert(SafeBaseEscrowV1.Unauthorized.selector);
        escrow.disputeEscrow(escrowId);
    }

    function testCancelEscrow() public {
        vm.prank(buyer);
        uint256 escrowId = escrow.createEscrow(
            seller,
            mediator,
            address(0),
            1 ether,
            block.timestamp + 1 days
        );

        vm.expectEmit(true, false, false, false);
        emit EscrowCancelled(escrowId);

        vm.prank(buyer);
        escrow.cancelEscrow(escrowId);

        SafeBaseEscrowV1.EscrowData memory escrowData = escrow.getEscrow(escrowId);
        assertTrue(escrowData.state == SafeBaseEscrowV1.EscrowState.Cancelled);
    }

    function testCancelEscrowWrongState() public {
        vm.prank(buyer);
        uint256 escrowId = escrow.createEscrow(
            seller,
            mediator,
            address(0),
            1 ether,
            block.timestamp + 1 days
        );

        vm.prank(buyer);
        escrow.fundEscrow{value: 1 ether}(escrowId);

        vm.prank(buyer);
        vm.expectRevert(SafeBaseEscrowV1.InvalidState.selector);
        escrow.cancelEscrow(escrowId);
    }

    function testPauseUnpause() public {
        vm.prank(owner);
        escrow.pause();

        vm.prank(buyer);
        vm.expectRevert();
        escrow.createEscrow(
            seller,
            mediator,
            address(0),
            1 ether,
            block.timestamp + 1 days
        );

        vm.prank(owner);
        escrow.unpause();

        vm.prank(buyer);
        uint256 escrowId = escrow.createEscrow(
            seller,
            mediator,
            address(0),
            1 ether,
            block.timestamp + 1 days
        );

        assertEq(escrowId, 1);
    }

    function testUpgradeAuthorization() public {
        SafeBaseEscrowV1 newImpl = new SafeBaseEscrowV1();

        vm.prank(buyer);
        vm.expectRevert();
        escrow.upgradeToAndCall(address(newImpl), "");

        vm.prank(owner);
        escrow.upgradeToAndCall(address(newImpl), "");
    }

    function testStateTransitions() public {
        vm.prank(buyer);
        uint256 escrowId = escrow.createEscrow(
            seller,
            mediator,
            address(0),
            1 ether,
            block.timestamp + 1 days
        );

        SafeBaseEscrowV1.EscrowData memory escrowData = escrow.getEscrow(escrowId);
        assertTrue(escrowData.state == SafeBaseEscrowV1.EscrowState.Created);

        vm.prank(buyer);
        escrow.fundEscrow{value: 1 ether}(escrowId);

        escrowData = escrow.getEscrow(escrowId);
        assertTrue(escrowData.state == SafeBaseEscrowV1.EscrowState.Funded);

        vm.prank(buyer);
        escrow.approveBuyer(escrowId);

        vm.prank(buyer);
        escrow.releaseToSeller(escrowId);

        escrowData = escrow.getEscrow(escrowId);
        assertTrue(escrowData.state == SafeBaseEscrowV1.EscrowState.Released);
    }

    function testInvalidStateTransitions() public {
        vm.prank(buyer);
        uint256 escrowId = escrow.createEscrow(
            seller,
            mediator,
            address(0),
            1 ether,
            block.timestamp + 1 days
        );

        vm.prank(buyer);
        vm.expectRevert(SafeBaseEscrowV1.InvalidState.selector);
        escrow.approveBuyer(escrowId);

        vm.prank(buyer);
        escrow.fundEscrow{value: 1 ether}(escrowId);

        vm.prank(buyer);
        vm.expectRevert(SafeBaseEscrowV1.InvalidState.selector);
        escrow.fundEscrow{value: 1 ether}(escrowId);
    }

    receive() external payable {}
}
