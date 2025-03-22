// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/EthereumChainToken.sol";

contract DeployEthereum is Script {
    function run() external {
        // Load environment variables
        address stargateRouter = vm.envAddress("STARGATE_ROUTER_ETHEREUM");
        uint32 ethereumEid = uint32(vm.envUint("ETHEREUM_ENDPOINT_ID"));
        uint32 arbEid = uint32(vm.envUint("ARBITRUM_ENDPOINT_ID"));
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        vm.startBroadcast(deployerPrivateKey);
        
        // Deploy the contract
        EthereumChainToken token = new EthereumChainToken(
            stargateRouter,
            ethereumEid,
            arbEid
        );
        
        console.log("EthereumChainToken deployed at:", address(token));
        
        vm.stopBroadcast();
    }
}