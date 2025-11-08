// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "forge-std/Script.sol";
import {Treasury} from "../src/Treasury.sol";
import {TreasuryV2} from "../src/TreasuryV2.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

contract UpgradeScript is Script {
    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address proxyAddress = vm.envAddress("PROXY_ADDRESS");

        console.log("=== SafeBase Treasury Upgrade ===");
        console.log("Proxy address:", proxyAddress);

        Treasury treasury = Treasury(payable(proxyAddress));

        // Verify current version
        console.log("Current owner:", treasury.owner());

        vm.startBroadcast(deployerPrivateKey);

        // Deploy new implementation
        TreasuryV2 newImplementation = new TreasuryV2();
        console.log("New implementation deployed:", address(newImplementation));

        // Upgrade proxy to new implementation
        treasury.upgradeToAndCall(address(newImplementation), "");
        console.log("Proxy upgraded successfully");

        vm.stopBroadcast();

        // Verify upgrade
        TreasuryV2 upgradedTreasury = TreasuryV2(payable(proxyAddress));
        uint256 version = upgradedTreasury.version();
        console.log("\n=== Upgrade Complete ===");
        console.log("New version:", version);
        console.log("Implementation:", address(newImplementation));

        console.log("\nVerify with:");
        console.log("forge verify-contract", address(newImplementation), "src/TreasuryV2.sol:TreasuryV2 --chain-id 84532");
    }
}
