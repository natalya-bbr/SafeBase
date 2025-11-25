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

    function deployTreasury(address owner) internal returns (address) {
        Treasury impl = new Treasury();
        bytes memory initData = abi.encodeWithSelector(Treasury.initialize.selector, owner, 2);
        ERC1967Proxy proxy = new ERC1967Proxy(address(impl), initData);
        console.log("Treasury Proxy:", address(proxy));
        return address(proxy);
    }

    function deployAccessController(address owner) internal returns (address) {
        AccessController impl = new AccessController();
        bytes memory initData = abi.encodeWithSelector(AccessController.initialize.selector, owner);
        ERC1967Proxy proxy = new ERC1967Proxy(address(impl), initData);
        console.log("AccessController Proxy:", address(proxy));
        return address(proxy);
    }

    function deployVerifier(address owner) internal returns (address) {
        Verifier impl = new Verifier();
        bytes memory initData = abi.encodeWithSelector(Verifier.initialize.selector, owner);
        ERC1967Proxy proxy = new ERC1967Proxy(address(impl), initData);
        console.log("Verifier Proxy:", address(proxy));
        return address(proxy);
    }

    function deployPaymentTracker(address owner) internal returns (address) {
        PaymentTracker impl = new PaymentTracker();
        bytes memory initData = abi.encodeWithSelector(PaymentTracker.initialize.selector, owner);
        ERC1967Proxy proxy = new ERC1967Proxy(address(impl), initData);
        console.log("PaymentTracker Proxy:", address(proxy));
        return address(proxy);
    }

    function deployBasePay(address owner) internal returns (address) {
        BasePay impl = new BasePay();
        bytes memory initData = abi.encodeWithSelector(BasePay.initialize.selector, owner);
        ERC1967Proxy proxy = new ERC1967Proxy(address(impl), initData);
        console.log("BasePay Proxy:", address(proxy));
        return address(proxy);
    }

    function deployRulesEngine(address owner) internal returns (address) {
        RulesEngineV1 impl = new RulesEngineV1();
        bytes memory initData = abi.encodeWithSelector(RulesEngineV1.initialize.selector, owner);
        ERC1967Proxy proxy = new ERC1967Proxy(address(impl), initData);
        console.log("RulesEngine Proxy:", address(proxy));
        return address(proxy);
    }

    function deployRegistry(address owner) internal returns (address) {
        RegistryV1 impl = new RegistryV1();
        bytes memory initData = abi.encodeWithSelector(RegistryV1.initialize.selector, owner);
        ERC1967Proxy proxy = new ERC1967Proxy(address(impl), initData);
        console.log("Registry Proxy:", address(proxy));
        return address(proxy);
    }

    function deployEscrow(address owner, address treasury) internal returns (address) {
        SafeBaseEscrowV1 impl = new SafeBaseEscrowV1();
        bytes memory initData = abi.encodeWithSelector(SafeBaseEscrowV1.initialize.selector, owner, treasury);
        ERC1967Proxy proxy = new ERC1967Proxy(address(impl), initData);
        console.log("SafeBaseEscrow Proxy:", address(proxy));
        return address(proxy);
    }

    function deployExecutor(address owner, address escrow, address rulesEngine) internal returns (address) {
        ExecutorV1 impl = new ExecutorV1();
        bytes memory initData = abi.encodeWithSelector(ExecutorV1.initialize.selector, owner, escrow, rulesEngine);
        ERC1967Proxy proxy = new ERC1967Proxy(address(impl), initData);
        console.log("Executor Proxy:", address(proxy));
        return address(proxy);
    }

    function configureContracts(Addresses memory addrs) internal {
        SafeBaseEscrowV1(addrs.escrow).setRulesEngine(addrs.rulesEngine);
        SafeBaseEscrowV1(addrs.escrow).setRegistry(addrs.registry);
        RegistryV1(addrs.registry).setEscrowContract(addrs.escrow);
        BasePay(addrs.basePay).setPaymentTracker(addrs.paymentTracker);
        BasePay(addrs.basePay).setEscrowContract(addrs.escrow);
    }

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address owner = vm.envAddress("OWNER_ADDRESS");

        console.log("=== SafeBase Escrow System Deployment ===");
        console.log("Owner:", owner);
        console.log("Chain ID:", block.chainid);

        vm.startBroadcast(deployerPrivateKey);

        Addresses memory addrs;
        addrs.treasury = deployTreasury(owner);
        addrs.accessController = deployAccessController(owner);
        addrs.verifier = deployVerifier(owner);
        addrs.paymentTracker = deployPaymentTracker(owner);
        addrs.basePay = deployBasePay(owner);
        addrs.rulesEngine = deployRulesEngine(owner);
        addrs.registry = deployRegistry(owner);
        addrs.escrow = deployEscrow(owner, addrs.treasury);
        addrs.executor = deployExecutor(owner, addrs.escrow, addrs.rulesEngine);

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
