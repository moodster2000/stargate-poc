// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


contract ArbReceiverFixed is ERC20, Ownable {
    // Stargate variables
    address public stargateRouter;
    address public ethereumContract;
    
    // Token economics
    uint256 public constant TOKENS_PER_ETH = 1000;

    // Events
    event TokensMinted(address indexed user, uint256 amount, uint256 ethReceived);
    event MessageReceived(bytes payload, address token, uint256 amount);
    event PayloadDecoded(address sender);
    event ReceivedFrom(address sender);

    constructor(
        address _stargateRouter
    ) ERC20("CrossChainToken", "CCT") Ownable(msg.sender) {
        stargateRouter = _stargateRouter;
    }

    function setEthereumContract(address _ethereumContract) external onlyOwner {
        ethereumContract = _ethereumContract;
    }

    // Direct token purchase on Arbitrum
    function buyTokens() external payable {
        require(msg.value > 0, "Must send ETH to buy tokens");
        
        // Calculate token amount
        uint256 tokenAmount = (msg.value * TOKENS_PER_ETH) / 1 ether;
        
        // Mint tokens to the buyer
        _mint(msg.sender, tokenAmount);
        
        emit TokensMinted(msg.sender, tokenAmount, msg.value);
    }
    
    // For manual token minting if needed
    function manualMintTokens(
        address _user,
        uint256 _amountReceived
    ) external onlyOwner {
        // Calculate tokens based on amount received
        uint256 tokenAmount = (_amountReceived * TOKENS_PER_ETH) / 1 ether;
        
        // Mint tokens to the user
        _mint(_user, tokenAmount);
        
        emit TokensMinted(_user, tokenAmount, _amountReceived);
    }
    
    // Owner can withdraw funds
    function withdraw() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }
    
    // Receive function for direct ETH transfers
    receive() external payable {
        // Log the receipt of ETH
        emit ReceivedFrom(msg.sender);
    }
}