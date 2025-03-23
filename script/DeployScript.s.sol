// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/EthereumInitiatorFixed.sol";
import "../src/ArbReceiverFixed.sol";

contract DeployEthereumInitiator is Script {
    function run() external {
        // Load environment variables
        address stargateRouter = vm.envAddress("STARGATE_ROUTER_ETHEREUM");
        uint32 ethereumEid = uint32(vm.envUint("ETHEREUM_ENDPOINT_ID"));
        uint32 arbEid = uint32(vm.envUint("ARBITRUM_ENDPOINT_ID"));
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        vm.startBroadcast(deployerPrivateKey);
        
        // Deploy the contract
        EthereumInitiatorFixed initiator = new EthereumInitiatorFixed(
            stargateRouter,
            ethereumEid,
            arbEid
        );
        
        console.log("EthereumInitiator deployed at:", address(initiator));
        
        vm.stopBroadcast();
    }
}

contract DeployArbReceiver is Script {
    function run() external {
        // Load environment variables
        address stargateRouter = vm.envAddress("STARGATE_ROUTER_ARBITRUM");
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        vm.startBroadcast(deployerPrivateKey);
        
        // Deploy the contract
        ArbReceiverFixed receiver = new ArbReceiverFixed(
            stargateRouter
        );
        
        console.log("ArbReceiver deployed at:", address(receiver));
        
        vm.stopBroadcast();
    }
}

contract SetReverseContractAddresses is Script {
    function run() external {
        // Load environment variables
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address ethereumContractAddress = vm.envAddress("ETHEREUM_INITIATOR_ADDRESS");
        address arbContractAddress = vm.envAddress("ARB_RECEIVER_ADDRESS");
        string memory rpcUrl = vm.envString("ETHEREUM_SEPOLIA_RPC_URL");
        
        vm.createSelectFork(rpcUrl);
        vm.startBroadcast(deployerPrivateKey);
        
        // Set arb contract on Ethereum
        EthereumInitiatorFixed ethereumToken = EthereumInitiatorFixed(payable(ethereumContractAddress));
        ethereumToken.setArbContract(arbContractAddress);
        console.log("Set arb contract on Ethereum to:", arbContractAddress);
        
        vm.stopBroadcast();
        
        // Switch to Arbitrum chain
        rpcUrl = vm.envString("ARBITRUM_SEPOLIA_RPC_URL");
        vm.createSelectFork(rpcUrl);
        vm.startBroadcast(deployerPrivateKey);
        
        // Set ethereum contract on Arbitrum
        ArbReceiverFixed arbToken = ArbReceiverFixed(payable(arbContractAddress));
        arbToken.setEthereumContract(ethereumContractAddress);
        console.log("Set ethereum contract on Arbitrum to:", ethereumContractAddress);
        
        vm.stopBroadcast();
    }
}

// // // For testing the sgReceive function on Arbitrum
// // contract TestSgReceive is Script {
// //     function run() external {
// //         // Load environment variables
// //         uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
// //         address arbContractAddress = vm.envAddress("ARB_RECEIVER_ADDRESS");
// //         string memory rpcUrl = vm.envString("ARBITRUM_SEPOLIA_RPC_URL");
        
// //         vm.createSelectFork(rpcUrl);
// //         vm.startBroadcast(deployerPrivateKey);
        
// //         // Create a test payload (simulating message from Ethereum)
// //         address testAddress = 0x1234567890123456789012345678901234567890;
// //         uint256 testAmount = 1 ether;
// //         bytes memory payload = abi.encode(testAddress, testAmount);
        
// //         // Call test function
// //         ArbReceiverFixed arbToken = ArbReceiverFixed(payable(arbContractAddress));
// //         arbToken.testSgReceive(payload, address(0), testAmount);
// //         console.log("Test sgReceive executed for:", testAddress);
        
// //         vm.stopBroadcast();
// //     }
// // }