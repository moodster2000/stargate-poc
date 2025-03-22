// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./interfaces/IStargate.sol";

library StargateHelper {
    function addressToBytes32(address _addr) internal pure returns (bytes32) {
        return bytes32(uint256(uint160(_addr)));
    }

    function bytes32ToAddress(bytes32 _b32) internal pure returns (address) {
        return address(uint160(uint256(_b32)));
    }

    // Helper to create a Taxi command (immediate bridging)
    function taxiCmd() internal pure returns (bytes memory) {
        return "";  // Empty bytes indicates taxi mode
    }

    // Helper to create a Bus command (batch bridging)
    function busCmd() internal pure returns (bytes memory) {
        return new bytes(1);  // A single byte indicates bus mode
    }
}