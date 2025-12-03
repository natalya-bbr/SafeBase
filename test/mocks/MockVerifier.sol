// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

contract MockVerifier {
    mapping(uint256 => bool) public shouldVerify;

    function setVerificationResult(uint256 escrowId, bool result) external {
        shouldVerify[escrowId] = result;
    }

    function verify(uint256 escrowId, bytes calldata) external view returns (bool) {
        return shouldVerify[escrowId];
    }
}
