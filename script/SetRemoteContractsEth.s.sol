// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/EthereumChainToken.sol";
import "../src/ArbChainTokenEth.sol";

contract SetRemoteContractsEth is Script {
    function run() external {
        // Load environment variables
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address ethereumContractAddress = vm.envAddress("ETHEREUM_CONTRACT_ADDRESS");
        address arbContractAddress = vm.envAddress("ARB_CONTRACT_ADDRESS");
        string memory rpcUrl = vm.envString("ETHEREUM_SEPOLIA_RPC_URL");
        
        vm.createSelectFork(rpcUrl);
        vm.startBroadcast(deployerPrivateKey);
        
        // Set remote contract on Ethereum
        EthereumChainToken ethereumToken = EthereumChainToken(payable(ethereumContractAddress));
        ethereumToken.setRemoteContract(arbContractAddress);
        console.log("Set remote contract on Ethereum to:", arbContractAddress);
        
        vm.stopBroadcast();
        
        // Switch to Arbitrum chain
        rpcUrl = vm.envString("ARBITRUM_SEPOLIA_RPC_URL");
        vm.createSelectFork(rpcUrl);
        vm.startBroadcast(deployerPrivateKey);
        
        // Set ethereum contract on Arbitrum
        ArbChainTokenEth arbToken = ArbChainTokenEth(payable(arbContractAddress));
        arbToken.setEthereumContract(ethereumContractAddress);
        console.log("Set ethereum contract on Arbitrum to:", ethereumContractAddress);
        
        vm.stopBroadcast();
    }
}