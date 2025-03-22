// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IStargate.sol";
import "./StargateHelper.sol";

contract EthereumChainToken is ERC20, Ownable {
    // Stargate V2 and LayerZero variables
    address public stargateRouter;
    uint32 public ethereumEid; 
    uint32 public arbEid;
    address public remoteContract;

    // Token economics
    uint256 public constant TOKENS_PER_ETH = 1000;
    uint256 public tokenPrice; // Price in wei per token

    event TokensPurchased(address indexed buyer, uint256 amount, uint256 cost);
    event FundsReceived(uint256 amount, uint32 fromEid);

    constructor(
        address _stargateRouter,
        uint32 _ethereumEid,
        uint32 _arbEid
    ) ERC20("CrossChainToken", "CCT") Ownable(msg.sender) {
        stargateRouter = _stargateRouter;
        ethereumEid = _ethereumEid;
        arbEid = _arbEid;
        tokenPrice = 0.001 ether; // 1 token costs 0.001 ETH
    }

    function setRemoteContract(address _remoteContract) external onlyOwner {
        remoteContract = _remoteContract;
    }

    function buyTokens() external payable {
        require(msg.value > 0, "Must send ETH to buy tokens");
        
        uint256 tokenAmount = (msg.value * TOKENS_PER_ETH) / 1 ether;
        _mint(msg.sender, tokenAmount);
        
        emit TokensPurchased(msg.sender, tokenAmount, msg.value);
    }

    // This is a simplified handler for receiving funds
    // The actual implementation would involve more complex handling with Stargate V2
    function onOFTReceived(
        uint32 _srcEid,
        bytes32 _from,
        uint256 _amount
    ) external {
        require(msg.sender == stargateRouter, "Only Stargate can call");
        require(_srcEid == arbEid, "Invalid source chain");
        
        address fromAddress = StargateHelper.bytes32ToAddress(_from);
        require(fromAddress == remoteContract, "Invalid source contract");
        
        emit FundsReceived(_amount, _srcEid);
    }

    function withdraw() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    // Function to receive ETH when bridged or sent directly
    receive() external payable {}
}