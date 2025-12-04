// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Test} from "forge-std/Test.sol";
import {Treasury} from "../src/Treasury.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {MockERC20} from "./mocks/MockERC20.sol";

contract TreasuryTest is Test {
    Treasury public treasury;
    MockERC20 public token;

    address public owner = address(1);
    address public admin1 = address(2);
    address public admin2 = address(3);
    address public executor = address(4);
    address public recipient = address(5);

    event AdminAdded(address indexed admin);
    event AdminRemoved(address indexed admin);
    event ExecutorAdded(address indexed executor);
    event ExecutorRemoved(address indexed executor);
    event Deposited(address indexed from, uint256 amount);
    event WithdrawalRequested(uint256 indexed requestId, address token, address to, uint256 amount);
    event WithdrawalApproved(uint256 indexed requestId, address indexed admin);
    event WithdrawalExecuted(uint256 indexed requestId);
    event WithdrawalCancelled(uint256 indexed requestId);

    function setUp() public {
        token = new MockERC20("Test Token", "TEST", 18);

        Treasury treasuryImpl = new Treasury();
        bytes memory treasuryData = abi.encodeWithSelector(
            Treasury.initialize.selector,
            owner,
            2
        );
        ERC1967Proxy treasuryProxy = new ERC1967Proxy(address(treasuryImpl), treasuryData);
        treasury = Treasury(payable(address(treasuryProxy)));

        vm.startPrank(owner);
        treasury.addAdmin(admin1);
        treasury.addAdmin(admin2);
        treasury.addExecutor(executor);
        vm.stopPrank();

        token.mint(address(treasury), 1000 ether);
        vm.deal(address(treasury), 100 ether);
    }

    function testInitialize() public view {
        assertEq(treasury.owner(), owner);
        assertEq(treasury.requiredApprovals(), 2);
    }

    function testAddAdmin() public {
        address newAdmin = address(6);

        vm.expectEmit(true, false, false, false);
        emit AdminAdded(newAdmin);

        vm.prank(owner);
        treasury.addAdmin(newAdmin);

        assertTrue(treasury.admins(newAdmin));
        assertEq(treasury.adminCount(), 3);
    }

    function testAddAdminOnlyOwner() public {
        vm.prank(address(99));
        vm.expectRevert();
        treasury.addAdmin(address(6));
    }

    function testRemoveAdmin() public {
        vm.expectEmit(true, false, false, false);
        emit AdminRemoved(admin1);

        vm.prank(owner);
        treasury.removeAdmin(admin1);

        assertFalse(treasury.admins(admin1));
        assertEq(treasury.adminCount(), 1);
    }

    function testAddExecutor() public {
        address newExecutor = address(7);

        vm.expectEmit(true, false, false, false);
        emit ExecutorAdded(newExecutor);

        vm.prank(owner);
        treasury.addExecutor(newExecutor);

        assertTrue(treasury.executors(newExecutor));
    }

    function testRemoveExecutor() public {
        vm.expectEmit(true, false, false, false);
        emit ExecutorRemoved(executor);

        vm.prank(owner);
        treasury.removeExecutor(executor);

        assertFalse(treasury.executors(executor));
    }

    function testRequestWithdrawal() public {
        vm.expectEmit(true, false, false, true);
        emit WithdrawalRequested(0, address(0), recipient, 1 ether);

        vm.prank(admin1);
        uint256 requestId = treasury.requestWithdrawal(address(0), recipient, 1 ether);

        assertEq(requestId, 0);
        assertEq(treasury.requestCount(), 1);
    }

    function testRequestWithdrawalOnlyAdmin() public {
        vm.prank(address(99));
        vm.expectRevert(Treasury.NotAdmin.selector);
        treasury.requestWithdrawal(address(0), recipient, 1 ether);
    }

    function testRequestWithdrawalZeroAddress() public {
        vm.prank(admin1);
        vm.expectRevert(Treasury.ZeroAddress.selector);
        treasury.requestWithdrawal(address(0), address(0), 1 ether);
    }

    function testRequestWithdrawalZeroAmount() public {
        vm.prank(admin1);
        vm.expectRevert(Treasury.ZeroAmount.selector);
        treasury.requestWithdrawal(address(0), recipient, 0);
    }

    function testRequestWithdrawalInsufficientBalance() public {
        vm.prank(admin1);
        vm.expectRevert(Treasury.InsufficientBalance.selector);
        treasury.requestWithdrawal(address(0), recipient, 1000 ether);
    }

    function testApproveWithdrawal() public {
        vm.prank(admin1);
        uint256 requestId = treasury.requestWithdrawal(address(0), recipient, 1 ether);

        vm.expectEmit(true, true, false, false);
        emit WithdrawalApproved(requestId, admin2);

        vm.prank(admin2);
        treasury.approveWithdrawal(requestId);
    }

    function testApproveWithdrawalOnlyAdmin() public {
        vm.prank(admin1);
        uint256 requestId = treasury.requestWithdrawal(address(0), recipient, 1 ether);

        vm.prank(address(99));
        vm.expectRevert(Treasury.NotAdmin.selector);
        treasury.approveWithdrawal(requestId);
    }

    function testApproveWithdrawalAlreadyApproved() public {
        vm.prank(admin1);
        uint256 requestId = treasury.requestWithdrawal(address(0), recipient, 1 ether);

        vm.prank(admin1);
        treasury.approveWithdrawal(requestId);

        vm.prank(admin1);
        vm.expectRevert(Treasury.AlreadyApproved.selector);
        treasury.approveWithdrawal(requestId);
    }

    function testExecuteWithdrawal() public {
        vm.prank(admin1);
        uint256 requestId = treasury.requestWithdrawal(address(0), recipient, 1 ether);

        vm.prank(admin1);
        treasury.approveWithdrawal(requestId);

        vm.prank(admin2);
        treasury.approveWithdrawal(requestId);

        uint256 recipientBalanceBefore = recipient.balance;

        vm.expectEmit(true, false, false, false);
        emit WithdrawalExecuted(requestId);

        vm.prank(executor);
        treasury.executeWithdrawal(requestId);

        assertEq(recipient.balance, recipientBalanceBefore + 1 ether);
    }

    function testExecuteWithdrawalOnlyExecutor() public {
        vm.prank(admin1);
        uint256 requestId = treasury.requestWithdrawal(address(0), recipient, 1 ether);

        vm.prank(admin1);
        treasury.approveWithdrawal(requestId);

        vm.prank(admin2);
        treasury.approveWithdrawal(requestId);

        vm.prank(address(99));
        vm.expectRevert(Treasury.NotExecutor.selector);
        treasury.executeWithdrawal(requestId);
    }

    function testExecuteWithdrawalInsufficientApprovals() public {
        vm.prank(admin1);
        uint256 requestId = treasury.requestWithdrawal(address(0), recipient, 1 ether);

        vm.prank(admin1);
        treasury.approveWithdrawal(requestId);

        vm.prank(executor);
        vm.expectRevert(Treasury.InvalidStatus.selector);
        treasury.executeWithdrawal(requestId);
    }

    function testExecuteWithdrawalERC20() public {
        vm.prank(admin1);
        uint256 requestId = treasury.requestWithdrawal(address(token), recipient, 10 ether);

        vm.prank(admin1);
        treasury.approveWithdrawal(requestId);

        vm.prank(admin2);
        treasury.approveWithdrawal(requestId);

        uint256 recipientBalanceBefore = token.balanceOf(recipient);

        vm.prank(executor);
        treasury.executeWithdrawal(requestId);

        assertEq(token.balanceOf(recipient), recipientBalanceBefore + 10 ether);
    }

    function testCancelWithdrawal() public {
        vm.prank(admin1);
        uint256 requestId = treasury.requestWithdrawal(address(0), recipient, 1 ether);

        vm.expectEmit(true, false, false, false);
        emit WithdrawalCancelled(requestId);

        vm.prank(admin1);
        treasury.cancelWithdrawal(requestId);
    }

    function testCancelWithdrawalOnlyAdmin() public {
        vm.prank(admin1);
        uint256 requestId = treasury.requestWithdrawal(address(0), recipient, 1 ether);

        vm.prank(address(99));
        vm.expectRevert(Treasury.NotAdmin.selector);
        treasury.cancelWithdrawal(requestId);
    }

    function testSetRequiredApprovals() public {
        vm.prank(owner);
        treasury.setRequiredApprovals(3);

        assertEq(treasury.requiredApprovals(), 3);
    }

    function testReceiveETH() public {
        uint256 balanceBefore = address(treasury).balance;

        vm.expectEmit(true, false, false, true);
        emit Deposited(address(this), 5 ether);

        (bool success,) = address(treasury).call{value: 5 ether}("");
        assertTrue(success);

        assertEq(address(treasury).balance, balanceBefore + 5 ether);
    }

    receive() external payable {}
}
