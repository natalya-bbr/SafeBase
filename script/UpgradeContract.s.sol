// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "forge-std/Script.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

import {Treasury} from "../src/Treasury.sol";
import {SafeBaseEscrowV1} from "../src/escrow/SafeBaseEscrowV1.sol";
import {RulesEngineV1} from "../src/escrow/RulesEngineV1.sol";
import {RegistryV1} from "../src/escrow/RegistryV1.sol";
import {ExecutorV1} from "../src/escrow/ExecutorV1.sol";
import {AccessController} from "../src/access/AccessController.sol";
import {Verifier} from "../src/integrations/Verifier.sol";
import {BasePay} from "../src/integrations/BasePay.sol";
import {PaymentTracker} from "../src/integrations/PaymentTracker.sol";

/**
 * @title UpgradeContractScript
 * @notice Universal UUPS upgrade script for SafeBase contracts
 * @dev Usage:
 *   forge script script/UpgradeContract.s.sol --rpc-url <RPC> --broadcast
 *   Environment variables:
 *   - PRIVATE_KEY: Deployer private key (must be contract owner)
 *   - UPGRADE_CONTRACT: Contract to upgrade (Treasury, SafeBaseEscrow, etc.)
 */
contract UpgradeContractScript is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        string memory contractToUpgrade = vm.envString("UPGRADE_CONTRACT");

        address proxyAddress = loadProxyAddress(contractToUpgrade);

        console.log("=== UUPS Contract Upgrade ===");
        console.log("Chain ID:", block.chainid);
        console.log("Contract:", contractToUpgrade);
        console.log("Proxy:", proxyAddress);

        vm.startBroadcast(deployerPrivateKey);

        address newImplementation = deployNewImplementation(contractToUpgrade);

        console.log("New Implementation:", newImplementation);
        console.log("Upgrading proxy...");

        // Call upgradeToAndCall on the proxy
        UUPSUpgradeable(proxyAddress).upgradeToAndCall(newImplementation, "");

        vm.stopBroadcast();

        console.log("=== Upgrade Complete ===");
        console.log("Proxy:", proxyAddress);
        console.log("New Implementation:", newImplementation);

        // Save to deployment file
        saveDeployment(contractToUpgrade, proxyAddress, newImplementation);
    }

    function deployNewImplementation(string memory contractName) internal returns (address) {
        bytes32 nameHash = keccak256(bytes(contractName));

        if (nameHash == keccak256("Treasury")) {
            Treasury impl = new Treasury();
            return address(impl);
        } else if (nameHash == keccak256("SafeBaseEscrow")) {
            SafeBaseEscrowV1 impl = new SafeBaseEscrowV1();
            return address(impl);
        } else if (nameHash == keccak256("RulesEngine")) {
            RulesEngineV1 impl = new RulesEngineV1();
            return address(impl);
        } else if (nameHash == keccak256("Registry")) {
            RegistryV1 impl = new RegistryV1();
            return address(impl);
        } else if (nameHash == keccak256("Executor")) {
            ExecutorV1 impl = new ExecutorV1();
            return address(impl);
        } else if (nameHash == keccak256("AccessController")) {
            AccessController impl = new AccessController();
            return address(impl);
        } else if (nameHash == keccak256("Verifier")) {
            Verifier impl = new Verifier();
            return address(impl);
        } else if (nameHash == keccak256("BasePay")) {
            BasePay impl = new BasePay();
            return address(impl);
        } else if (nameHash == keccak256("PaymentTracker")) {
            PaymentTracker impl = new PaymentTracker();
            return address(impl);
        } else {
            revert(string.concat("Unknown contract: ", contractName));
        }
    }

    function loadProxyAddress(string memory contractName) internal view returns (address) {
        uint256 chainId = block.chainid;
        string memory root = vm.projectRoot();
        string memory path;

        if (chainId == 8453) {
            path = string.concat(root, "/deployments/8453.json");
        } else if (chainId == 84532) {
            path = string.concat(root, "/deployments/84532.json");
        } else {
            revert("Unsupported chain");
        }

        string memory json = vm.readFile(path);
        string memory jsonPath = string.concat(".contracts.", contractName, ".proxy");

        address proxyAddr = vm.parseJsonAddress(json, jsonPath);
        require(proxyAddr != address(0), "Proxy address not found");

        return proxyAddr;
    }

    function saveDeployment(
        string memory contractName,
        address proxyAddress,
        address implementationAddress
    ) internal {
        uint256 chainId = block.chainid;
        string memory root = vm.projectRoot();
        string memory path;

        if (chainId == 8453) {
            path = string.concat(root, "/deployments/8453.json");
        } else if (chainId == 84532) {
            path = string.concat(root, "/deployments/84532.json");
        } else {
            return; // Don't save for unsupported chains
        }

        // Read existing JSON
        string memory existingJson = vm.readFile(path);

        // Create new contract entry
        string memory contractJson = string.concat(
            '{"proxy":"', vm.toString(proxyAddress),
            '","implementation":"', vm.toString(implementationAddress), '"}'
        );

        // Log the update (actual file writing would need additional tooling)
        console.log("\n=== Update deployment file manually ===");
        console.log("File:", path);
        console.log("Contract:", contractName);
        console.log("New implementation:", implementationAddress);
    }
}
