// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import "../src/interfaces/IStargate.sol";
import "../src/StargateHelper.sol";

contract TestStargateRouter is Script {
    function run() external {
        // Load environment variables
        address stargateRouter = vm.envAddress("STARGATE_ROUTER_ARBITRUM_V2");
        uint32 optimismEid = uint32(vm.envUint("OPTIMISM_ENDPOINT_ID"));
        uint32 arbEid = uint32(vm.envUint("ARBITRUM_ENDPOINT_ID"));
        address optimismContract = vm.envAddress("OPTIMISM_CONTRACT_ADDRESS_V2");
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        // Create a fork of Arbitrum testnet
        vm.createSelectFork(vm.envString("ARBITRUM_SEPOLIA_RPC_URL"));
        
        console.log("=== Stargate Router Test ===");
        console.log("Router address:", stargateRouter);
        console.log("Optimism EID:", optimismEid);
        console.log("Arbitrum EID:", arbEid);
        console.log("Optimism contract:", optimismContract);
        
        // Create a SendParam structure for testing
        IOFT.SendParam memory sendParam = IOFT.SendParam({
            dstEid: optimismEid,
            to: StargateHelper.addressToBytes32(optimismContract),
            amountLD: 0.01 ether,
            minAmountLD: 0,
            extraOptions: new bytes(0),
            composeMsg: new bytes(0),
            oftCmd: StargateHelper.taxiCmd() // Use taxi mode
        });
        
        IStargate stargate = IStargate(stargateRouter);
        
        // Test each function with try/catch to identify which one is failing
        console.log("\n=== Testing Router Interface ===");
        
        // Test token() function
        try stargate.token() returns (address tokenAddress) {
            console.log("token() returned:", tokenAddress);
        } catch Error(string memory reason) {
            console.log("token() failed with reason:", reason);
        } catch {
            console.log("token() failed with unknown error");
        }
        
        // Test stargateType() function
        try stargate.stargateType() returns (StargateType stargateType) {
            console.log("stargateType() returned:", uint(stargateType));
        } catch Error(string memory reason) {
            console.log("stargateType() failed with reason:", reason);
        } catch {
            console.log("stargateType() failed with unknown error");
        }
        
        // Test quoteOFT() function
        try stargate.quoteOFT(sendParam) returns (
            OFTLimit memory limit,
            OFTFeeDetail[] memory feeDetails,
            IOFT.OFTReceipt memory receipt
        ) {
            console.log("quoteOFT() succeeded");
            console.log("  Min amount:", limit.minAmountLD);
            console.log("  Max amount:", limit.maxAmountLD);
            console.log("  Receipt amount sent:", receipt.amountSentLD);
            console.log("  Receipt amount received:", receipt.amountReceivedLD);
            console.log("  Fee details count:", feeDetails.length);
            
            for (uint i = 0; i < feeDetails.length; i++) {
                // console.log("  Fee detail", i, ":", feeDetails[i].feeAmountLD, feeDetails[i].description);
            }
        } catch Error(string memory reason) {
            console.log("quoteOFT() failed with reason:", reason);
        } catch {
            console.log("quoteOFT() failed with unknown error");
        }
        
        // Test quoteSend() function
        try stargate.quoteSend(sendParam, false) returns (IOFT.MessagingFee memory fee) {
            console.log("quoteSend() succeeded");
            console.log("  Native fee:", fee.nativeFee);
            console.log("  LZ token fee:", fee.lzTokenFee);
        } catch Error(string memory reason) {
            console.log("quoteSend() failed with reason:", reason);
        } catch {
            console.log("quoteSend() failed with unknown error");
        }
        
        // Attempt to do a real transaction (will fail but gives us info)
        console.log("\n=== Attempting Transaction ===");
        vm.startBroadcast(deployerPrivateKey);
        
        try stargate.sendToken{value: 0.01 ether}(
            sendParam,
            IOFT.MessagingFee({nativeFee: 0.005 ether, lzTokenFee: 0}),
            vm.addr(deployerPrivateKey)
        ) {
            console.log("sendToken() succeeded (unexpected!)");
        } catch Error(string memory reason) {
            console.log("sendToken() failed with reason:", reason);
        } catch (bytes memory lowLevelData) {
            console.log("sendToken() failed with low-level error");
            
            // Try to decode the revert reason
            // try vm.parseBytes(lowLevelData) returns (string memory reason) {
            //     console.log("Decoded error:", reason);
            // } catch {
            //     console.log("Could not decode error");
            // }
        }
        
        vm.stopBroadcast();
    }
}