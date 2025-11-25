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

contract DeployProxyScript is Script {
    struct Addresses {
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

    function loadExistingAddresses() internal view returns (Addresses memory) {
        uint256 chainId = block.chainid;
        string memory root = vm.projectRoot();
        string memory path;

        if (chainId == 8453) {
            path = string.concat(root, "/deployments/8453.json");
        } else if (chainId == 84532) {
            path = string.concat(root, "/deployments/84532.json");
        } else {
            console.log("Warning: Unsupported chain, deploying all contracts fresh");
            return Addresses(address(0), address(0), address(0), address(0), address(0), address(0), address(0), address(0), address(0));
        }

        try vm.readFile(path) returns (string memory json) {
            Addresses memory addrs;

            try vm.parseJsonAddress(json, ".contracts.Treasury.proxy") returns (address addr) {
                if (addr != address(0)) addrs.treasury = addr;
            } catch {}

            try vm.parseJsonAddress(json, ".contracts.AccessController.proxy") returns (address addr) {
                if (addr != address(0)) addrs.accessController = addr;
            } catch {}

            try vm.parseJsonAddress(json, ".contracts.Verifier.proxy") returns (address addr) {
                if (addr != address(0)) addrs.verifier = addr;
            } catch {}

            try vm.parseJsonAddress(json, ".contracts.PaymentTracker.proxy") returns (address addr) {
                if (addr != address(0)) addrs.paymentTracker = addr;
            } catch {}

            try vm.parseJsonAddress(json, ".contracts.BasePay.proxy") returns (address addr) {
                if (addr != address(0)) addrs.basePay = addr;
            } catch {}

            try vm.parseJsonAddress(json, ".contracts.RulesEngine.proxy") returns (address addr) {
                if (addr != address(0)) addrs.rulesEngine = addr;
            } catch {}

            try vm.parseJsonAddress(json, ".contracts.Registry.proxy") returns (address addr) {
                if (addr != address(0)) addrs.registry = addr;
            } catch {}

            try vm.parseJsonAddress(json, ".contracts.SafeBaseEscrow.proxy") returns (address addr) {
                if (addr != address(0)) addrs.escrow = addr;
            } catch {}

            try vm.parseJsonAddress(json, ".contracts.Executor.proxy") returns (address addr) {
                if (addr != address(0)) addrs.executor = addr;
            } catch {}

            return addrs;
        } catch {
            console.log("Warning: Could not read deployments JSON, deploying all contracts fresh");
            return Addresses(address(0), address(0), address(0), address(0), address(0), address(0), address(0), address(0), address(0));
        }
    }

    function deployTreasury(address owner, address existing) internal returns (address) {
        if (existing != address(0)) {
            console.log("Treasury already deployed at:", existing);
            return existing;
        }
        Treasury impl = new Treasury();
        bytes memory initData = abi.encodeWithSelector(Treasury.initialize.selector, owner, 2);
        ERC1967Proxy proxy = new ERC1967Proxy(address(impl), initData);
        console.log("Treasury deployed - Proxy:", address(proxy), "Impl:", address(impl));
        return address(proxy);
    }

    function deployAccessController(address owner, address existing) internal returns (address) {
        if (existing != address(0)) {
            console.log("AccessController already deployed at:", existing);
            return existing;
        }
        AccessController impl = new AccessController();
        bytes memory initData = abi.encodeWithSelector(AccessController.initialize.selector, owner);
        ERC1967Proxy proxy = new ERC1967Proxy(address(impl), initData);
        console.log("AccessController deployed - Proxy:", address(proxy), "Impl:", address(impl));
        return address(proxy);
    }

    function deployVerifier(address owner, address existing) internal returns (address) {
        if (existing != address(0)) {
            console.log("Verifier already deployed at:", existing);
            return existing;
        }
        Verifier impl = new Verifier();
        bytes memory initData = abi.encodeWithSelector(Verifier.initialize.selector, owner);
        ERC1967Proxy proxy = new ERC1967Proxy(address(impl), initData);
        console.log("Verifier deployed - Proxy:", address(proxy), "Impl:", address(impl));
        return address(proxy);
    }

    function deployPaymentTracker(address owner, address existing) internal returns (address) {
        if (existing != address(0)) {
            console.log("PaymentTracker already deployed at:", existing);
            return existing;
        }
        PaymentTracker impl = new PaymentTracker();
        bytes memory initData = abi.encodeWithSelector(PaymentTracker.initialize.selector, owner);
        ERC1967Proxy proxy = new ERC1967Proxy(address(impl), initData);
        console.log("PaymentTracker deployed - Proxy:", address(proxy), "Impl:", address(impl));
        return address(proxy);
    }

    function deployBasePay(address owner, address existing) internal returns (address) {
        if (existing != address(0)) {
            console.log("BasePay already deployed at:", existing);
            return existing;
        }
        BasePay impl = new BasePay();
        bytes memory initData = abi.encodeWithSelector(BasePay.initialize.selector, owner);
        ERC1967Proxy proxy = new ERC1967Proxy(address(impl), initData);
        console.log("BasePay deployed - Proxy:", address(proxy), "Impl:", address(impl));
        return address(proxy);
    }

    function deployRulesEngine(address owner, address existing) internal returns (address) {
        if (existing != address(0)) {
            console.log("RulesEngine already deployed at:", existing);
            return existing;
        }
        RulesEngineV1 impl = new RulesEngineV1();
        bytes memory initData = abi.encodeWithSelector(RulesEngineV1.initialize.selector, owner);
        ERC1967Proxy proxy = new ERC1967Proxy(address(impl), initData);
        console.log("RulesEngine deployed - Proxy:", address(proxy), "Impl:", address(impl));
        return address(proxy);
    }

    function deployRegistry(address owner, address existing) internal returns (address) {
        if (existing != address(0)) {
            console.log("Registry already deployed at:", existing);
            return existing;
        }
        RegistryV1 impl = new RegistryV1();
        bytes memory initData = abi.encodeWithSelector(RegistryV1.initialize.selector, owner);
        ERC1967Proxy proxy = new ERC1967Proxy(address(impl), initData);
        console.log("Registry deployed - Proxy:", address(proxy), "Impl:", address(impl));
        return address(proxy);
    }

    function deployEscrow(address owner, address treasury, address existing) internal returns (address) {
        if (existing != address(0)) {
            console.log("SafeBaseEscrow already deployed at:", existing);
            return existing;
        }
        SafeBaseEscrowV1 impl = new SafeBaseEscrowV1();
        bytes memory initData = abi.encodeWithSelector(SafeBaseEscrowV1.initialize.selector, owner, treasury);
        ERC1967Proxy proxy = new ERC1967Proxy(address(impl), initData);
        console.log("SafeBaseEscrow deployed - Proxy:", address(proxy), "Impl:", address(impl));
        return address(proxy);
    }

    function deployExecutor(address owner, address escrow, address rulesEngine, address existing) internal returns (address) {
        if (existing != address(0)) {
            console.log("Executor already deployed at:", existing);
            return existing;
        }
        ExecutorV1 impl = new ExecutorV1();
        bytes memory initData = abi.encodeWithSelector(ExecutorV1.initialize.selector, owner, escrow, rulesEngine);
        ERC1967Proxy proxy = new ERC1967Proxy(address(impl), initData);
        console.log("Executor deployed - Proxy:", address(proxy), "Impl:", address(impl));
        return address(proxy);
    }

    function configureContracts(Addresses memory addrs) internal {
        if (addrs.escrow != address(0) && addrs.rulesEngine != address(0) && addrs.registry != address(0)) {
            try SafeBaseEscrowV1(addrs.escrow).setRulesEngine(addrs.rulesEngine) {
                console.log("Configured SafeBaseEscrow.setRulesEngine");
            } catch {
                console.log("SafeBaseEscrow.setRulesEngine already configured or failed");
            }

            try SafeBaseEscrowV1(addrs.escrow).setRegistry(addrs.registry) {
                console.log("Configured SafeBaseEscrow.setRegistry");
            } catch {
                console.log("SafeBaseEscrow.setRegistry already configured or failed");
            }
        }

        if (addrs.registry != address(0) && addrs.escrow != address(0)) {
            try RegistryV1(addrs.registry).setEscrowContract(addrs.escrow) {
                console.log("Configured Registry.setEscrowContract");
            } catch {
                console.log("Registry.setEscrowContract already configured or failed");
            }
        }

        if (addrs.basePay != address(0) && addrs.paymentTracker != address(0) && addrs.escrow != address(0)) {
            try BasePay(addrs.basePay).setPaymentTracker(addrs.paymentTracker) {
                console.log("Configured BasePay.setPaymentTracker");
            } catch {
                console.log("BasePay.setPaymentTracker already configured or failed");
            }

            try BasePay(addrs.basePay).setEscrowContract(addrs.escrow) {
                console.log("Configured BasePay.setEscrowContract");
            } catch {
                console.log("BasePay.setEscrowContract already configured or failed");
            }
        }
    }

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address owner = vm.envAddress("OWNER_ADDRESS");

        console.log("=== SafeBase Smart Deployment ===");
        console.log("Owner:", owner);
        console.log("Chain ID:", block.chainid);

        Addresses memory existing = loadExistingAddresses();

        if (existing.treasury != address(0)) {
            console.log("\nFound existing deployments, will skip already deployed contracts");
        } else {
            console.log("\nNo existing deployments found, deploying all contracts fresh");
        }

        vm.startBroadcast(deployerPrivateKey);

        Addresses memory addrs;
        addrs.treasury = deployTreasury(owner, existing.treasury);
        addrs.accessController = deployAccessController(owner, existing.accessController);
        addrs.verifier = deployVerifier(owner, existing.verifier);
        addrs.paymentTracker = deployPaymentTracker(owner, existing.paymentTracker);
        addrs.basePay = deployBasePay(owner, existing.basePay);
        addrs.rulesEngine = deployRulesEngine(owner, existing.rulesEngine);
        addrs.registry = deployRegistry(owner, existing.registry);
        addrs.escrow = deployEscrow(owner, addrs.treasury, existing.escrow);
        addrs.executor = deployExecutor(owner, addrs.escrow, addrs.rulesEngine, existing.executor);

        configureContracts(addrs);

        vm.stopBroadcast();

        console.log("\n=== Deployment Complete ===");
        console.log("Treasury:", addrs.treasury);
        console.log("AccessController:", addrs.accessController);
        console.log("Verifier:", addrs.verifier);
        console.log("PaymentTracker:", addrs.paymentTracker);
        console.log("BasePay:", addrs.basePay);
        console.log("RulesEngine:", addrs.rulesEngine);
        console.log("Registry:", addrs.registry);
        console.log("SafeBaseEscrow:", addrs.escrow);
        console.log("Executor:", addrs.executor);
    }
}
