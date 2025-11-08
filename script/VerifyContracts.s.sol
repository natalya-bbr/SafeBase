// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "forge-std/Script.sol";

/**
 * @title VerifyContracts
 * @notice Helper script to generate verification commands for Basescan
 * @dev Run this script to get the commands needed to verify contracts
 */
contract VerifyContractsScript is Script {
    function run() public view {
        address implementation = vm.envOr("IMPLEMENTATION_ADDRESS", address(0));
        address proxy = vm.envOr("PROXY_ADDRESS", address(0));
        uint256 chainId = block.chainid;

        string memory network = chainId == 8453 ? "base" : "base-sepolia";
        string memory explorerUrl = chainId == 8453
            ? "https://basescan.org"
            : "https://sepolia.basescan.org";

        console.log("=== Contract Verification Commands ===\n");
        console.log("Network:", network);
        console.log("Chain ID:", chainId);
        console.log("Explorer:", explorerUrl);
        console.log("");

        if (implementation != address(0)) {
            console.log("1. Verify Treasury Implementation:");
            console.log("   forge verify-contract \\");
            console.log("     ", vm.toString(implementation), "\\");
            console.log("      src/Treasury.sol:Treasury \\");
            console.log("      --chain-id", vm.toString(chainId), "\\");
            console.log("      --watch");
            console.log("");
        }

        if (proxy != address(0)) {
            console.log("2. Verify Proxy Contract:");
            console.log("   Note: ERC1967Proxy is from OpenZeppelin and should auto-verify");
            console.log("   Proxy address:", vm.toString(proxy));
            console.log("");
        }

        console.log("3. Verify TreasuryV2 (after upgrade):");
        console.log("   forge verify-contract \\");
        console.log("     <TREASURY_V2_ADDRESS> \\");
        console.log("      src/TreasuryV2.sol:TreasuryV2 \\");
        console.log("      --chain-id", vm.toString(chainId), "\\");
        console.log("      --watch");
        console.log("");

        console.log("=== Environment Variables ===");
        console.log("Make sure BASESCAN_API_KEY is set in your .env file");
        console.log("export BASESCAN_API_KEY=your_api_key_here");
    }
}
