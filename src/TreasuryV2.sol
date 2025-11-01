// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Treasury} from "./Treasury.sol";

contract TreasuryV2 is Treasury {
    mapping(bytes32 => bool) public basePayTransactions;

    event BasePayTransactionProcessed(bytes32 indexed txId);

    function processBasePayTransaction(bytes32 txId, address token, address to, uint256 amount) external onlyAdmin {
        require(!basePayTransactions[txId], "Already processed");
        basePayTransactions[txId] = true;

        emit BasePayTransactionProcessed(txId);
    }

    function version() external pure returns (uint256) {
        return 2;
    }
}
