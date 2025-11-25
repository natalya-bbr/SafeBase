// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "forge-std/Script.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

import {Treasury} from "../src/Treasury.sol";
import {SafeBaseEscrowV1} from "../src/escrow/SafeBaseEscrowV1.sol";
import {RulesEngineV1} from "../src/escrow/RulesEngineV1.sol";
import {RegistryV1} from "../src/escrow/RegistryV1.sol";
import {ExecutorV1} from "../src/escrow/ExecutorV1.sol";
import {AccessController} from "../src/access/AccessController.sol";
import {Verifier} from "../src/integrations/Verifier.sol";
import {BasePay} from "../src/integrations/BasePay.sol";
import {PaymentTracker} from "../src/integrations/PaymentTracker.sol";

contract DeployModularScript is Script {
    struct ExistingAddresses {
        address treasury;
        address accessController;
        address verifier;
        address paymentTracker;
        address basePay;
        address rulesEngine;
        address registry;
        address escrow;
        address executor;
    }

    function loadExistingAddresses() internal view returns (ExistingAddresses memory) {
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

        ExistingAddresses memory addrs;
        addrs.treasury = vm.parseJsonAddress(json, ".contracts.Treasury.proxy");

        try vm.parseJsonAddress(json, ".contracts.AccessController.proxy") returns (address addr) {
            addrs.accessController = addr;
        } catch {}

        try vm.parseJsonAddress(json, ".contracts.Verifier.proxy") returns (address addr) {
            addrs.verifier = addr;
        } catch {}

        try vm.parseJsonAddress(json, ".contracts.PaymentTracker.proxy") returns (address addr) {
            addrs.paymentTracker = addr;
        } catch {}

        try vm.parseJsonAddress(json, ".contracts.BasePay.proxy") returns (address addr) {
            addrs.basePay = addr;
        } catch {}

        try vm.parseJsonAddress(json, ".contracts.RulesEngine.proxy") returns (address addr) {
            addrs.rulesEngine = addr;
        } catch {}

        try vm.parseJsonAddress(json, ".contracts.Registry.proxy") returns (address addr) {
            addrs.registry = addr;
        } catch {}

        try vm.parseJsonAddress(json, ".contracts.SafeBaseEscrow.proxy") returns (address addr) {
            addrs.escrow = addr;
        } catch {}

        try vm.parseJsonAddress(json, ".contracts.Executor.proxy") returns (address addr) {
            addrs.executor = addr;
        } catch {}

        return addrs;
    }

    function deployContract(string memory contractName, address owner, ExistingAddresses memory existing) internal returns (address) {
        bytes32 nameHash = keccak256(bytes(contractName));

        if (nameHash == keccak256("Treasury")) {
            if (existing.treasury != address(0)) {
                console.log("Treasury already deployed:", existing.treasury);
                return existing.treasury;
            }
            Treasury impl = new Treasury();
            bytes memory initData = abi.encodeWithSelector(Treasury.initialize.selector, owner, 2);
            ERC1967Proxy proxy = new ERC1967Proxy(address(impl), initData);
            console.log("Treasury deployed - Proxy:", address(proxy), "Impl:", address(impl));
            return address(proxy);
        }

        if (nameHash == keccak256("AccessController")) {
            if (existing.accessController != address(0)) {
                console.log("AccessController already deployed:", existing.accessController);
                return existing.accessController;
            }
            AccessController impl = new AccessController();
            bytes memory initData = abi.encodeWithSelector(AccessController.initialize.selector, owner);
            ERC1967Proxy proxy = new ERC1967Proxy(address(impl), initData);
            console.log("AccessController deployed - Proxy:", address(proxy), "Impl:", address(impl));
            return address(proxy);
        }

        if (nameHash == keccak256("Verifier")) {
            if (existing.verifier != address(0)) {
                console.log("Verifier already deployed:", existing.verifier);
                return existing.verifier;
            }
            Verifier impl = new Verifier();
            bytes memory initData = abi.encodeWithSelector(Verifier.initialize.selector, owner);
            ERC1967Proxy proxy = new ERC1967Proxy(address(impl), initData);
            console.log("Verifier deployed - Proxy:", address(proxy), "Impl:", address(impl));
            return address(proxy);
        }

        if (nameHash == keccak256("PaymentTracker")) {
            if (existing.paymentTracker != address(0)) {
                console.log("PaymentTracker already deployed:", existing.paymentTracker);
                return existing.paymentTracker;
            }
            PaymentTracker impl = new PaymentTracker();
            bytes memory initData = abi.encodeWithSelector(PaymentTracker.initialize.selector, owner);
            ERC1967Proxy proxy = new ERC1967Proxy(address(impl), initData);
            console.log("PaymentTracker deployed - Proxy:", address(proxy), "Impl:", address(impl));
            return address(proxy);
        }

        if (nameHash == keccak256("BasePay")) {
            if (existing.basePay != address(0)) {
                console.log("BasePay already deployed:", existing.basePay);
                return existing.basePay;
            }
            BasePay impl = new BasePay();
            bytes memory initData = abi.encodeWithSelector(BasePay.initialize.selector, owner);
            ERC1967Proxy proxy = new ERC1967Proxy(address(impl), initData);
            console.log("BasePay deployed - Proxy:", address(proxy), "Impl:", address(impl));
            return address(proxy);
        }

        if (nameHash == keccak256("RulesEngine")) {
            if (existing.rulesEngine != address(0)) {
                console.log("RulesEngine already deployed:", existing.rulesEngine);
                return existing.rulesEngine;
            }
            RulesEngineV1 impl = new RulesEngineV1();
            bytes memory initData = abi.encodeWithSelector(RulesEngineV1.initialize.selector, owner);
            ERC1967Proxy proxy = new ERC1967Proxy(address(impl), initData);
            console.log("RulesEngine deployed - Proxy:", address(proxy), "Impl:", address(impl));
            return address(proxy);
        }

        if (nameHash == keccak256("Registry")) {
            if (existing.registry != address(0)) {
                console.log("Registry already deployed:", existing.registry);
                return existing.registry;
            }
            RegistryV1 impl = new RegistryV1();
            bytes memory initData = abi.encodeWithSelector(RegistryV1.initialize.selector, owner);
            ERC1967Proxy proxy = new ERC1967Proxy(address(impl), initData);
            console.log("Registry deployed - Proxy:", address(proxy), "Impl:", address(impl));
            return address(proxy);
        }

        if (nameHash == keccak256("SafeBaseEscrow")) {
            if (existing.escrow != address(0)) {
                console.log("SafeBaseEscrow already deployed:", existing.escrow);
                return existing.escrow;
            }
            require(existing.treasury != address(0), "Treasury must be deployed first");
            SafeBaseEscrowV1 impl = new SafeBaseEscrowV1();
            bytes memory initData = abi.encodeWithSelector(SafeBaseEscrowV1.initialize.selector, owner, existing.treasury);
            ERC1967Proxy proxy = new ERC1967Proxy(address(impl), initData);
            console.log("SafeBaseEscrow deployed - Proxy:", address(proxy), "Impl:", address(impl));
            return address(proxy);
        }

        if (nameHash == keccak256("Executor")) {
            if (existing.executor != address(0)) {
                console.log("Executor already deployed:", existing.executor);
                return existing.executor;
            }
            require(existing.escrow != address(0), "SafeBaseEscrow must be deployed first");
            require(existing.rulesEngine != address(0), "RulesEngine must be deployed first");
            ExecutorV1 impl = new ExecutorV1();
            bytes memory initData = abi.encodeWithSelector(ExecutorV1.initialize.selector, owner, existing.escrow, existing.rulesEngine);
            ERC1967Proxy proxy = new ERC1967Proxy(address(impl), initData);
            console.log("Executor deployed - Proxy:", address(proxy), "Impl:", address(impl));
            return address(proxy);
        }

        revert("Unknown contract name");
    }

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address owner = vm.envAddress("OWNER_ADDRESS");
        string memory targetContract = vm.envOr("DEPLOY_CONTRACT", string("all"));

        console.log("=== SafeBase Modular Deployment ===");
        console.log("Chain ID:", block.chainid);
        console.log("Owner:", owner);
        console.log("Target:", targetContract);

        ExistingAddresses memory existing = loadExistingAddresses();

        vm.startBroadcast(deployerPrivateKey);

        if (keccak256(bytes(targetContract)) == keccak256("all")) {
            console.log("\n--- Deploying all contracts ---");

            existing.treasury = deployContract("Treasury", owner, existing);
            existing.accessController = deployContract("AccessController", owner, existing);
            existing.verifier = deployContract("Verifier", owner, existing);
            existing.paymentTracker = deployContract("PaymentTracker", owner, existing);
            existing.basePay = deployContract("BasePay", owner, existing);
            existing.rulesEngine = deployContract("RulesEngine", owner, existing);
            existing.registry = deployContract("Registry", owner, existing);
            existing.escrow = deployContract("SafeBaseEscrow", owner, existing);
            existing.executor = deployContract("Executor", owner, existing);

            if (existing.escrow != address(0) && existing.rulesEngine != address(0) && existing.registry != address(0)) {
                SafeBaseEscrowV1(existing.escrow).setRulesEngine(existing.rulesEngine);
                SafeBaseEscrowV1(existing.escrow).setRegistry(existing.registry);
                console.log("Configured SafeBaseEscrow");
            }

            if (existing.registry != address(0) && existing.escrow != address(0)) {
                RegistryV1(existing.registry).setEscrowContract(existing.escrow);
                console.log("Configured Registry");
            }

            if (existing.basePay != address(0) && existing.paymentTracker != address(0) && existing.escrow != address(0)) {
                BasePay(existing.basePay).setPaymentTracker(existing.paymentTracker);
                BasePay(existing.basePay).setEscrowContract(existing.escrow);
                console.log("Configured BasePay");
            }
        } else {
            console.log("\n--- Deploying single contract ---");
            deployContract(targetContract, owner, existing);
        }

        vm.stopBroadcast();

        console.log("\n=== Deployment Complete ===");
        console.log("Treasury:", existing.treasury);
        console.log("AccessController:", existing.accessController);
        console.log("Verifier:", existing.verifier);
        console.log("PaymentTracker:", existing.paymentTracker);
        console.log("BasePay:", existing.basePay);
        console.log("RulesEngine:", existing.rulesEngine);
        console.log("Registry:", existing.registry);
        console.log("SafeBaseEscrow:", existing.escrow);
        console.log("Executor:", existing.executor);
    }
}
