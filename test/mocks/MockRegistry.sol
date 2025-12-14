// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

contract MockRegistry {
    uint256 public lastEscrowId;
    uint8 public lastState;
    struct Indexed {
        address buyer;
        address seller;
        uint256 amount;
        uint256 createdAt;
    }
    mapping(uint256 => Indexed) public indexedEscrows;

    function indexEscrow(
        uint256 escrowId,
        address buyer,
        address seller,
        uint256 amount,
        uint256 createdAt
    ) external {
        indexedEscrows[escrowId] = Indexed(buyer, seller, amount, createdAt);
        lastEscrowId = escrowId;
    }

    function updateEscrowState(uint256 escrowId, uint8 state) external {
        lastEscrowId = escrowId;
        lastState = state;
    }
}

