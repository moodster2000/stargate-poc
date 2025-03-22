// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/interfaces/IStargate.sol";

contract CheckStargateV2 is Script {
    function run() external {
        // Load environment variables
        address stargateRouter = vm.envAddress("STARGATE_ROUTER_ARBITRUM_V2");
        uint32 optimismEid = uint32(vm.envUint("OPTIMISM_ENDPOINT_ID"));
        
        // Create a fork of Arbitrum testnet
        vm.createSelectFork(vm.envString("ARBITRUM_SEPOLIA_RPC_URL"));
        
        console.log("Checking Stargate Router V2 at:", stargateRouter);
        
        // Try to get the token address
        IStargate stargate = IStargate(stargateRouter);
        
        try stargate.token() returns (address tokenAddress) {
            console.log("Token address:", tokenAddress);
        } catch {
            console.log("Failed to get token address");
        }
        
        // Try to get the Stargate type
        try stargate.stargateType() returns (StargateType stargateType) {
            console.log("Stargate type:", uint(stargateType));
        } catch {
            console.log("Failed to get Stargate type");
        }
    }
}