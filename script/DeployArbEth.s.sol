// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/ArbChainTokenEth.sol";

contract DeployArbEth is Script {
    function run() external {
        // Load environment variables
        address stargateRouter = vm.envAddress("STARGATE_ROUTER_ARBITRUM");
        uint32 ethereumEid = uint32(vm.envUint("ETHEREUM_ENDPOINT_ID"));
        uint32 arbEid = uint32(vm.envUint("ARBITRUM_ENDPOINT_ID"));
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        vm.startBroadcast(deployerPrivateKey);
        
        // Deploy the contract
        ArbChainTokenEth token = new ArbChainTokenEth(
            stargateRouter,
            ethereumEid,
            arbEid
        );
        
        console.log("ArbChainTokenEth deployed at:", address(token));
        
        vm.stopBroadcast();
    }
}