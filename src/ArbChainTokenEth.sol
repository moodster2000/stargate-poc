// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IStargate.sol";
import "./StargateHelper.sol";

contract ArbChainTokenEth is ERC20, Ownable {
    // Stargate V2 and LayerZero variables
    address public stargateRouter;
    uint32 public ethereumEid; // Endpoint ID for Ethereum
    uint32 public arbEid;      // Endpoint ID for Arbitrum
    address public ethereumContract;
    
    // Token economics
    uint256 public constant TOKENS_PER_ETH = 1000;
    uint256 public tokenPrice; // Price in wei per token
    
    // Event for tracking failures
    event BridgingFailed(string reason);
    event TokensPurchased(address indexed buyer, uint256 amount, uint256 cost);
    event FundsBridged(address indexed sender, uint256 amount, uint32 destEid);

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

    function setEthereumContract(address _ethereumContract) external onlyOwner {
        ethereumContract = _ethereumContract;
    }

    function buyTokens() external payable {
        require(msg.value > 0, "Must send ETH to buy tokens");
        require(ethereumContract != address(0), "Ethereum contract not set");
        
        // Calculate token amount
        uint256 tokenAmount = (msg.value * TOKENS_PER_ETH) / 1 ether;
        
        // Mint tokens for the buyer
        _mint(msg.sender, tokenAmount);
        
        // Bridge the ETH to Ethereum using Stargate V2
        _bridgeToEthereum(msg.value);
        
        emit TokensPurchased(msg.sender, tokenAmount, msg.value);
    }
    
    function _bridgeToEthereum(uint256 _amount) internal {
        IStargate stargate = IStargate(stargateRouter);
        
        // Create the SendParam structure - Using taxi mode first since Ethereum has higher limits
        IOFT.SendParam memory sendParam = IOFT.SendParam({
            dstEid: ethereumEid,
            to: StargateHelper.addressToBytes32(ethereumContract),
            amountLD: _amount,
            minAmountLD: 0,  // Will be updated from quote
            extraOptions: new bytes(0),
            composeMsg: new bytes(0),
            oftCmd: StargateHelper.taxiCmd()  // Using taxi mode
        });
        
        try stargate.quoteOFT(sendParam) returns (
            OFTLimit memory limit,
            OFTFeeDetail[] memory,
            IOFT.OFTReceipt memory receipt
        ) {
            // Update minAmountLD based on the quote
            sendParam.minAmountLD = receipt.amountReceivedLD;
            
            // Get the fee quote
            IOFT.MessagingFee memory fee = stargate.quoteSend(sendParam, false);
            
            // Make sure we have enough ETH to cover fees
            require(address(this).balance >= _amount + fee.nativeFee, "Insufficient ETH for bridge + fee");
            
            // Send the tokens
            try stargate.sendToken{value: _amount + fee.nativeFee}(
                sendParam,
                fee,
                msg.sender  // Refund address
            ) returns (IOFT.MessagingReceipt memory, IOFT.OFTReceipt memory, Ticket memory) {
                emit FundsBridged(msg.sender, _amount, ethereumEid);
            } catch Error(string memory reason) {
                // If bridging fails with a reason, log it
                emit BridgingFailed(reason);
                
                // Refund the ETH
                (bool success, ) = payable(msg.sender).call{value: address(this).balance}("");
                require(success, "Refund failed");
            } catch (bytes memory) {
                // If bridging fails with a low-level error (like Path_InsufficientCredit)
                emit BridgingFailed("Low-level error (likely insufficient credits)");
                
                // Try with bus mode instead
                sendParam.oftCmd = StargateHelper.busCmd();
                
                try stargate.quoteOFT(sendParam) returns (
                    OFTLimit memory busLimit,
                    OFTFeeDetail[] memory,
                    IOFT.OFTReceipt memory busReceipt
                ) {
                    sendParam.minAmountLD = busReceipt.amountReceivedLD;
                    IOFT.MessagingFee memory busFee = stargate.quoteSend(sendParam, false);
                    
                    try stargate.sendToken{value: _amount + busFee.nativeFee}(
                        sendParam,
                        busFee,
                        msg.sender
                    ) {
                        emit FundsBridged(msg.sender, _amount, ethereumEid);
                    } catch {
                        // If bus mode also fails, refund
                        emit BridgingFailed("Both taxi and bus mode failed");
                        (bool success, ) = payable(msg.sender).call{value: address(this).balance}("");
                        require(success, "Refund failed");
                    }
                } catch {
                    // If bus quote fails, refund
                    emit BridgingFailed("Bus mode quote failed");
                    (bool success, ) = payable(msg.sender).call{value: address(this).balance}("");
                    require(success, "Refund failed");
                }
            }
        } catch {
            // If quoting fails, refund the ETH
            emit BridgingFailed("Quote failed");
            (bool success, ) = payable(msg.sender).call{value: address(this).balance}("");
            require(success, "Refund failed");
        }
    }

    // Function to receive ETH
    receive() external payable {}
}