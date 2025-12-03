// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Test} from "forge-std/Test.sol";
import {RegistryV1} from "../src/escrow/RegistryV1.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract RegistryV1Test is Test {
    RegistryV1 public registry;

    address public owner = address(1);
    address public escrowContract = address(2);
    address public buyer = address(3);
    address public seller = address(4);

    event EscrowIndexed(uint256 indexed escrowId, address indexed buyer, address indexed seller);
    event EscrowUpdated(uint256 indexed escrowId, uint8 state);

    function setUp() public {
        RegistryV1 registryImpl = new RegistryV1();
        bytes memory registryData = abi.encodeWithSelector(
            RegistryV1.initialize.selector,
            owner
        );
        ERC1967Proxy registryProxy = new ERC1967Proxy(address(registryImpl), registryData);
        registry = RegistryV1(address(registryProxy));

        vm.prank(owner);
        registry.setEscrowContract(escrowContract);
    }

    function testInitialize() public view {
        assertEq(registry.owner(), owner);
    }

    function testSetEscrowContract() public {
        RegistryV1 newRegistry = RegistryV1(address(new ERC1967Proxy(
            address(new RegistryV1()),
            abi.encodeWithSelector(RegistryV1.initialize.selector, owner)
        )));

        vm.prank(owner);
        newRegistry.setEscrowContract(address(999));

        assertEq(newRegistry.escrowContract(), address(999));
    }

    function testSetEscrowContractOnlyOwner() public {
        vm.prank(address(99));
        vm.expectRevert();
        registry.setEscrowContract(address(999));
    }

    function testIndexEscrow() public {
        vm.expectEmit(true, true, true, false);
        emit EscrowIndexed(1, buyer, seller);

        vm.prank(escrowContract);
        registry.indexEscrow(1, buyer, seller, 1 ether, block.timestamp);

        RegistryV1.EscrowMetadata memory metadata = registry.getEscrowMetadata(1);
        assertEq(metadata.buyer, buyer);
        assertEq(metadata.seller, seller);
        assertEq(metadata.amount, 1 ether);
        assertEq(metadata.createdAt, block.timestamp);
        assertEq(metadata.state, 0);
    }

    function testIndexEscrowUnauthorized() public {
        vm.prank(address(99));
        vm.expectRevert(RegistryV1.Unauthorized.selector);
        registry.indexEscrow(1, buyer, seller, 1 ether, block.timestamp);
    }

    function testUpdateEscrowState() public {
        vm.prank(escrowContract);
        registry.indexEscrow(1, buyer, seller, 1 ether, block.timestamp);

        vm.expectEmit(true, false, false, true);
        emit EscrowUpdated(1, 1);

        vm.prank(escrowContract);
        registry.updateEscrowState(1, 1);

        RegistryV1.EscrowMetadata memory metadata = registry.getEscrowMetadata(1);
        assertEq(metadata.state, 1);
    }

    function testUpdateEscrowStateUnauthorized() public {
        vm.prank(escrowContract);
        registry.indexEscrow(1, buyer, seller, 1 ether, block.timestamp);

        vm.prank(address(99));
        vm.expectRevert(RegistryV1.Unauthorized.selector);
        registry.updateEscrowState(1, 1);
    }

    function testGetPartyEscrows() public {
        vm.startPrank(escrowContract);
        registry.indexEscrow(1, buyer, seller, 1 ether, block.timestamp);
        registry.indexEscrow(2, buyer, address(5), 2 ether, block.timestamp);
        registry.indexEscrow(3, address(6), seller, 3 ether, block.timestamp);
        vm.stopPrank();

        uint256[] memory buyerEscrows = registry.getPartyEscrows(buyer);
        assertEq(buyerEscrows.length, 2);
        assertEq(buyerEscrows[0], 1);
        assertEq(buyerEscrows[1], 2);

        uint256[] memory sellerEscrows = registry.getPartyEscrows(seller);
        assertEq(sellerEscrows.length, 2);
        assertEq(sellerEscrows[0], 1);
        assertEq(sellerEscrows[1], 3);
    }

    function testGetEscrowsPaginated() public {
        vm.startPrank(escrowContract);
        for (uint256 i = 1; i <= 10; i++) {
            registry.indexEscrow(i, buyer, seller, i * 1 ether, block.timestamp);
        }
        vm.stopPrank();

        uint256[] memory page1 = registry.getEscrowsPaginated(0, 5);
        assertEq(page1.length, 5);
        assertEq(page1[0], 1);
        assertEq(page1[4], 5);

        uint256[] memory page2 = registry.getEscrowsPaginated(5, 5);
        assertEq(page2.length, 5);
        assertEq(page2[0], 6);
        assertEq(page2[4], 10);

        uint256[] memory page3 = registry.getEscrowsPaginated(8, 5);
        assertEq(page3.length, 2);
        assertEq(page3[0], 9);
        assertEq(page3[1], 10);

        uint256[] memory page4 = registry.getEscrowsPaginated(100, 5);
        assertEq(page4.length, 0);
    }

    function testGetTotalEscrowCount() public {
        vm.startPrank(escrowContract);
        registry.indexEscrow(1, buyer, seller, 1 ether, block.timestamp);
        registry.indexEscrow(2, buyer, seller, 2 ether, block.timestamp);
        registry.indexEscrow(3, buyer, seller, 3 ether, block.timestamp);
        vm.stopPrank();

        assertEq(registry.getTotalEscrowCount(), 3);
    }

    function testGetPartyEscrowCount() public {
        vm.startPrank(escrowContract);
        registry.indexEscrow(1, buyer, seller, 1 ether, block.timestamp);
        registry.indexEscrow(2, buyer, address(5), 2 ether, block.timestamp);
        registry.indexEscrow(3, address(6), seller, 3 ether, block.timestamp);
        vm.stopPrank();

        assertEq(registry.getPartyEscrowCount(buyer), 2);
        assertEq(registry.getPartyEscrowCount(seller), 2);
        assertEq(registry.getPartyEscrowCount(address(5)), 1);
        assertEq(registry.getPartyEscrowCount(address(6)), 1);
    }
}
