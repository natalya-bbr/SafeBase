// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Test} from "forge-std/Test.sol";
import {ExecutorV1} from "../src/escrow/ExecutorV1.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract MockEscrow {
    struct EscrowData {
        address buyer;
        address seller;
        address mediator;
        address token;
        uint256 amount;
        uint256 deadline;
        uint8 state;
        bool buyerApproved;
        bool sellerApproved;
        bytes32 paymentId;
        uint256 createdAt;
    }

    EscrowData public escrowData;

    function setEscrow(
        address buyer,
        uint256 deadline,
        uint8 state,
        bool buyerApproved,
        bool sellerApproved
    ) external {
        escrowData.buyer = buyer;
        escrowData.deadline = deadline;
        escrowData.state = state;
        escrowData.buyerApproved = buyerApproved;
        escrowData.sellerApproved = sellerApproved;
    }

    function getEscrow(uint256) external view returns (
        address, address, address, address, uint256, uint256, uint8, bool, bool, bytes32, uint256
    ) {
        return (
            escrowData.buyer,
            escrowData.seller,
            escrowData.mediator,
            escrowData.token,
            escrowData.amount,
            escrowData.deadline,
            escrowData.state,
            escrowData.buyerApproved,
            escrowData.sellerApproved,
            escrowData.paymentId,
            escrowData.createdAt
        );
    }

    function refundToBuyer(uint256) external {}
    function releaseToSeller(uint256) external {}
}

contract MockRulesEngine {
    bool public shouldAllow;

    function setCanRelease(bool _shouldAllow) external {
        shouldAllow = _shouldAllow;
    }

    function canRelease(
        uint256,
        bool,
        bool,
        bool,
        uint256,
        bytes calldata
    ) external view returns (bool) {
        return shouldAllow;
    }

    function canRefund(uint256, uint256, bool) external view returns (bool) {
        return shouldAllow;
    }
}

contract ExecutorV1Test is Test {
    ExecutorV1 public executor;
    MockEscrow public escrowContract;
    MockRulesEngine public rulesEngine;

    address public owner = address(1);
    address public automator = address(2);

    event DeadlineCheckScheduled(uint256 indexed escrowId, uint256 deadline);
    event AutoRefundExecuted(uint256 indexed escrowId);
    event AutoReleaseExecuted(uint256 indexed escrowId);
    event AutomatorAdded(address indexed automator);
    event AutomatorRemoved(address indexed automator);

    function setUp() public {
        escrowContract = new MockEscrow();
        rulesEngine = new MockRulesEngine();

        ExecutorV1 executorImpl = new ExecutorV1();
        bytes memory executorData = abi.encodeWithSelector(
            ExecutorV1.initialize.selector,
            owner,
            address(escrowContract),
            address(rulesEngine)
        );
        ERC1967Proxy executorProxy = new ERC1967Proxy(address(executorImpl), executorData);
        executor = ExecutorV1(address(executorProxy));
    }

    function testInitialize() public view {
        assertEq(executor.owner(), owner);
        assertEq(address(executor.escrowContract()), address(escrowContract));
        assertEq(address(executor.rulesEngine()), address(rulesEngine));
    }

    function testAddAutomator() public {
        vm.expectEmit(true, false, false, false);
        emit AutomatorAdded(automator);

        vm.prank(owner);
        executor.addAutomator(automator);

        assertTrue(executor.automators(automator));
    }

    function testAddAutomatorOnlyOwner() public {
        vm.prank(address(99));
        vm.expectRevert();
        executor.addAutomator(automator);
    }

    function testRemoveAutomator() public {
        vm.prank(owner);
        executor.addAutomator(automator);

        vm.expectEmit(true, false, false, false);
        emit AutomatorRemoved(automator);

        vm.prank(owner);
        executor.removeAutomator(automator);

        assertFalse(executor.automators(automator));
    }

    function testScheduleDeadlineCheck() public {
        vm.prank(owner);
        executor.addAutomator(automator);

        uint256 deadline = block.timestamp + 1 days;

        vm.expectEmit(true, false, false, true);
        emit DeadlineCheckScheduled(1, deadline);

        vm.prank(automator);
        executor.scheduleDeadlineCheck(1, deadline);

        assertTrue(executor.scheduledForRefund(1));
    }

    function testScheduleDeadlineCheckOnlyAutomator() public {
        uint256 deadline = block.timestamp + 1 days;

        vm.prank(address(99));
        vm.expectRevert(ExecutorV1.Unauthorized.selector);
        executor.scheduleDeadlineCheck(1, deadline);
    }

    function testExecuteAutoRefund() public {
        vm.prank(owner);
        executor.addAutomator(automator);

        escrowContract.setEscrow(address(3), block.timestamp - 1, 1, false, false);
        rulesEngine.setCanRelease(true);

        vm.expectEmit(true, false, false, false);
        emit AutoRefundExecuted(1);

        vm.prank(automator);
        executor.executeAutoRefund(1, 1);

        assertFalse(executor.scheduledForRefund(1));
    }

    function testExecuteAutoRefundBeforeDeadline() public {
        vm.prank(owner);
        executor.addAutomator(automator);

        escrowContract.setEscrow(address(3), block.timestamp + 1 days, 1, false, false);
        rulesEngine.setCanRelease(false);

        vm.prank(automator);
        vm.expectRevert(ExecutorV1.DeadlineNotReached.selector);
        executor.executeAutoRefund(1, 1);
    }

    function testExecuteAutoRelease() public {
        vm.prank(owner);
        executor.addAutomator(automator);

        escrowContract.setEscrow(address(3), block.timestamp + 1 days, 1, true, true);
        rulesEngine.setCanRelease(true);

        vm.expectEmit(true, false, false, false);
        emit AutoReleaseExecuted(1);

        vm.prank(automator);
        executor.executeAutoRelease(1, 1);

        assertFalse(executor.scheduledForRelease(1));
    }

    function testCheckAndExecuteDeadlines() public {
        vm.prank(owner);
        executor.addAutomator(automator);

        escrowContract.setEscrow(address(3), block.timestamp - 1, 1, false, false);
        rulesEngine.setCanRelease(true);

        uint256[] memory escrowIds = new uint256[](1);
        escrowIds[0] = 1;

        vm.prank(automator);
        executor.checkAndExecuteDeadlines(escrowIds, 1);
    }

    function testOnlyAutomatorModifier() public {
        vm.prank(address(99));
        vm.expectRevert(ExecutorV1.Unauthorized.selector);
        executor.scheduleDeadlineCheck(1, block.timestamp + 1 days);
    }

    function testOwnerCanExecuteAutomatorFunctions() public {
        uint256 deadline = block.timestamp + 1 days;

        vm.prank(owner);
        executor.scheduleDeadlineCheck(1, deadline);

        assertTrue(executor.scheduledForRefund(1));
    }
}
