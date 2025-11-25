// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract Verifier is Initializable, UUPSUpgradeable, OwnableUpgradeable {
    mapping(uint256 => bool) public verifiedEscrows;
    mapping(address => bool) public trustedVerifiers;

    event EscrowVerified(uint256 indexed escrowId, address indexed verifier);
    event VerifierTrusted(address indexed verifier);
    event VerifierUntrusted(address indexed verifier);

    error Unauthorized();
    error AlreadyVerified();
    error NotTrusted();

    function initialize(address _owner) public initializer {
        __Ownable_init(_owner);
    }

    function trustVerifier(address _verifier) external onlyOwner {
        trustedVerifiers[_verifier] = true;
        emit VerifierTrusted(_verifier);
    }

    function untrustVerifier(address _verifier) external onlyOwner {
        trustedVerifiers[_verifier] = false;
        emit VerifierUntrusted(_verifier);
    }

    function verifyEscrow(uint256 _escrowId) external {
        if (!trustedVerifiers[msg.sender]) revert NotTrusted();
        if (verifiedEscrows[_escrowId]) revert AlreadyVerified();

        verifiedEscrows[_escrowId] = true;
        emit EscrowVerified(_escrowId, msg.sender);
    }

    function verify(uint256 _escrowId, bytes calldata) external view returns (bool) {
        return verifiedEscrows[_escrowId];
    }

    function isVerified(uint256 _escrowId) external view returns (bool) {
        return verifiedEscrows[_escrowId];
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    uint256[50] private __gap;
}
