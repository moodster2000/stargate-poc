// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import "../src/interfaces/IStargate.sol";
import "../src/StargateHelper.sol";

contract TestRoutes is Script {
    // Common endpoint IDs
    uint32[] public endpointIds = [
        40161, // Ethereum
        40102, // BSC
        40340, // Story
        40231, // Arbitrum Sepolia
        40232  // Optimism Sepolia
        // Add more as needed
    ];
    
    function run() external {
        address stargateRouter = vm.envAddress("STARGATE_ROUTER_ARBITRUM_V2");
        
        // Create a fork of Arbitrum testnet
        vm.createSelectFork(vm.envString("ARBITRUM_SEPOLIA_RPC_URL"));
        
        console.log("=== Testing Routes from Arbitrum Sepolia ===");
        
        for (uint i = 0; i < endpointIds.length; i++) {
            uint32 dstEid = endpointIds[i];
            if (dstEid == 40231) continue; // Skip self
            
            console.log("\nTesting route to EID:", dstEid);
            
            testRoute(stargateRouter, dstEid);
        }
    }
    
    function testRoute(address _router, uint32 _destEid) internal {
        IStargate stargate = IStargate(_router);
        
        // Mock destination address
        bytes32 mockDest = StargateHelper.addressToBytes32(address(0x123));
        
        // Create test SendParam
        IOFT.SendParam memory sendParam = IOFT.SendParam({
            dstEid: _destEid,
            to: mockDest,
            amountLD: 0.01 ether,
            minAmountLD: 0,
            extraOptions: new bytes(0),
            composeMsg: new bytes(0),
            oftCmd: StargateHelper.taxiCmd() // Try taxi mode first
        });
        
        // Test quoteOFT
        try stargate.quoteOFT(sendParam) returns (
            OFTLimit memory limit,
            OFTFeeDetail[] memory,
            IOFT.OFTReceipt memory receipt
        ) {
            console.log("Route AVAILABLE (quoteOFT succeeded)");
            console.log("Min amount:", limit.minAmountLD);
            console.log("Max amount:", limit.maxAmountLD);
            
            // Also try bus mode
            sendParam.oftCmd = StargateHelper.busCmd();
            try stargate.quoteOFT(sendParam) {
                console.log("Bus mode also supported");
            } catch {
                console.log("Bus mode NOT supported");
            }
            
        } catch Error(string memory reason) {
            console.log("Route UNAVAILABLE. Reason:", reason);
        } catch {
            console.log("Route UNAVAILABLE (unknown error)");
        }
    }
}