// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "forge-std/Script.sol";
import {Treasury} from "../src/Treasury.sol";

/**
 * @title ConfigManager
 * @notice Manage Treasury configuration (roles, approvals, etc.)
 * @dev Use environment variables to specify actions
 */
contract ConfigManagerScript is Script {
    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address proxyAddress = vm.envAddress("PROXY_ADDRESS");

        Treasury treasury = Treasury(payable(proxyAddress));

        console.log("=== SafeBase Config Manager ===");
        console.log("Treasury:", proxyAddress);
        console.log("Owner:", treasury.owner());
        console.log("Required Approvals:", treasury.requiredApprovals());
        console.log("");

        // Read action from environment
        string memory action = vm.envOr("ACTION", string("view"));

        if (keccak256(bytes(action)) == keccak256(bytes("view"))) {
            viewConfig(treasury);
        } else if (keccak256(bytes(action)) == keccak256(bytes("add-admin"))) {
            address newAdmin = vm.envAddress("ADMIN_ADDRESS");
            addAdmin(treasury, deployerPrivateKey, newAdmin);
        } else if (keccak256(bytes(action)) == keccak256(bytes("remove-admin"))) {
            address adminToRemove = vm.envAddress("ADMIN_ADDRESS");
            removeAdmin(treasury, deployerPrivateKey, adminToRemove);
        } else if (keccak256(bytes(action)) == keccak256(bytes("add-executor"))) {
            address newExecutor = vm.envAddress("EXECUTOR_ADDRESS");
            addExecutor(treasury, deployerPrivateKey, newExecutor);
        } else if (keccak256(bytes(action)) == keccak256(bytes("remove-executor"))) {
            address executorToRemove = vm.envAddress("EXECUTOR_ADDRESS");
            removeExecutor(treasury, deployerPrivateKey, executorToRemove);
        } else if (keccak256(bytes(action)) == keccak256(bytes("set-approvals"))) {
            uint256 newApprovals = vm.envUint("NEW_APPROVALS");
            setRequiredApprovals(treasury, deployerPrivateKey, newApprovals);
        } else {
            console.log("Unknown action:", action);
            console.log("\nAvailable actions:");
            console.log("  view - View current configuration");
            console.log("  add-admin - Add new admin (requires ADMIN_ADDRESS)");
            console.log("  remove-admin - Remove admin (requires ADMIN_ADDRESS)");
            console.log("  add-executor - Add executor (requires EXECUTOR_ADDRESS)");
            console.log("  remove-executor - Remove executor (requires EXECUTOR_ADDRESS)");
            console.log("  set-approvals - Set required approvals (requires NEW_APPROVALS)");
        }
    }

    function viewConfig(Treasury treasury) internal view {
        console.log("=== Current Configuration ===");
        console.log("Owner:", treasury.owner());
        console.log("Required Approvals:", treasury.requiredApprovals());
        console.log("\nUse isAdmin(address) and isExecutor(address) to check roles");
    }

    function addAdmin(Treasury treasury, uint256 privateKey, address newAdmin) internal {
        vm.startBroadcast(privateKey);
        treasury.addAdmin(newAdmin);
        vm.stopBroadcast();
        console.log("Added admin:", newAdmin);
    }

    function removeAdmin(Treasury treasury, uint256 privateKey, address admin) internal {
        vm.startBroadcast(privateKey);
        treasury.removeAdmin(admin);
        vm.stopBroadcast();
        console.log("Removed admin:", admin);
    }

    function addExecutor(Treasury treasury, uint256 privateKey, address newExecutor) internal {
        vm.startBroadcast(privateKey);
        treasury.addExecutor(newExecutor);
        vm.stopBroadcast();
        console.log("Added executor:", newExecutor);
    }

    function removeExecutor(Treasury treasury, uint256 privateKey, address executor) internal {
        vm.startBroadcast(privateKey);
        treasury.removeExecutor(executor);
        vm.stopBroadcast();
        console.log("Removed executor:", executor);
    }

    function setRequiredApprovals(Treasury treasury, uint256 privateKey, uint256 newApprovals) internal {
        vm.startBroadcast(privateKey);
        treasury.setRequiredApprovals(newApprovals);
        vm.stopBroadcast();
        console.log("Updated required approvals to:", newApprovals);
    }
}
