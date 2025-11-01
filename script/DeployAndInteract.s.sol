// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "forge-std/Script.sol";
import {Treasury} from "../src/Treasury.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract DeployAndInteractScript is Script {
    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address owner = vm.envAddress("OWNER_ADDRESS");
        uint256 requiredApprovals = vm.envOr("REQUIRED_APPROVALS", uint256(2));

        console.log("=== SafeBase Deployment ===");
        console.log("Owner:", owner);
        console.log("Required Approvals:", requiredApprovals);

        vm.startBroadcast(deployerPrivateKey);

        Treasury implementation = new Treasury();
        console.log("Treasury implementation:", address(implementation));

        bytes memory initData = abi.encodeWithSelector(
            Treasury.initialize.selector,
            owner,
            requiredApprovals
        );

        ERC1967Proxy proxy = new ERC1967Proxy(address(implementation), initData);
        console.log("Treasury proxy:", address(proxy));

        Treasury treasury = Treasury(payable(address(proxy)));

        address admin1 = address(uint160(uint256(keccak256("admin1"))));
        address admin2 = address(uint160(uint256(keccak256("admin2"))));
        address executor1 = address(uint160(uint256(keccak256("executor1"))));

        treasury.addAdmin(admin1);
        console.log("Added admin1:", admin1);

        treasury.addAdmin(admin2);
        console.log("Added admin2:", admin2);

        treasury.addExecutor(executor1);
        console.log("Added executor1:", executor1);

        if (address(treasury).balance == 0) {
            payable(address(treasury)).transfer(0.001 ether);
            console.log("Deposited 0.001 ETH to treasury");
        }

        vm.stopBroadcast();

        console.log("\n=== Deployment Complete ===");
        console.log("Treasury:", address(treasury));
        console.log("Implementation:", address(implementation));
        console.log("\nVerify with:");
        console.log("forge verify-contract", address(implementation), "src/Treasury.sol:Treasury --chain-id 84532");
    }
}
