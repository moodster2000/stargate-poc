// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IStargate.sol";
import "./StargateHelper.sol";

contract EthereumInitiatorFixed is ERC20, Ownable {
    // Stargate V2 and LayerZero variables
    address public stargateRouter;
    uint32 public ethereumEid; 
    uint32 public arbEid;
    address public arbContract;

    // Events
    event BridgingFailed(string reason);
    event BridgeInitiated(address indexed user, uint256 amount, uint64 nonce);

    constructor(
        address _stargateRouter,
        uint32 _ethereumEid,
        uint32 _arbEid
    ) ERC20("CrossChainToken", "CCT") Ownable(msg.sender) {
        stargateRouter = _stargateRouter;
        ethereumEid = _ethereumEid;
        arbEid = _arbEid;
    }

    function setArbContract(address _arbContract) external onlyOwner {
        arbContract = _arbContract;
    }

    // User buys tokens and initiates bridge to Arbitrum
    function buyTokensAndBridge() external payable {
        require(msg.value > 0, "Must send ETH to buy tokens");
        require(arbContract != address(0), "Arbitrum contract not set");
        
        // Bridge the ETH to Arbitrum
        _bridgeToArbitrum(msg.value);
    }
    
    function _bridgeToArbitrum(uint256 _amount) internal {
        IStargate stargate = IStargate(stargateRouter);
        
        // Create a properly encoded message with sender info and amount
        // This is critical - must match the decoding in the receiver
        bytes memory composeMsg = abi.encode(msg.sender, _amount);
        
        // Create the SendParam structure
        IOFT.SendParam memory sendParam = IOFT.SendParam({
            dstEid: arbEid,
            to: StargateHelper.addressToBytes32(arbContract),
            amountLD: _amount,
            minAmountLD: 0,
            extraOptions: new bytes(0),
            composeMsg: composeMsg,
            oftCmd: StargateHelper.taxiCmd()  // Use taxi for immediate delivery
        });
        
        // First get a quote to estimate fees and received amount
        try stargate.quoteOFT(sendParam) returns (
            OFTLimit memory,
            OFTFeeDetail[] memory,
            IOFT.OFTReceipt memory receipt
        ) {
            // Update min amount based on quote
            sendParam.minAmountLD = receipt.amountReceivedLD;
            
            // Get messaging fee
            IOFT.MessagingFee memory fee = stargate.quoteSend(sendParam, false);
            
            // Send the tokens with proper value
            // Important: value must cover both the bridged amount and the fee
            try stargate.sendToken{value: _amount + fee.nativeFee}(
                sendParam,
                fee,
                msg.sender  // Refund address
            ) returns (IOFT.MessagingReceipt memory msgReceipt, IOFT.OFTReceipt memory, Ticket memory) {
                emit BridgeInitiated(msg.sender, _amount, msgReceipt.nonce);
            } catch Error(string memory reason) {
                _refundUser(reason);
            } catch {
                _refundUser("Bridge transaction failed");
            }
        } catch Error(string memory reason) {
            _refundUser(reason);
        } catch {
            _refundUser("Quote failed");
        }
    }

    // Helper function to refund user and emit event
    function _refundUser(string memory reason) internal {
        emit BridgingFailed(reason);
        (bool success, ) = payable(msg.sender).call{value: msg.value}("");
        require(success, "Refund failed");
    }

    // Function to receive ETH
    receive() external payable {}
}