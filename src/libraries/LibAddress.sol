// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

/// @custom:security-contact contact@stack3.dev
library LibAddress {
    /**
     * @dev Converts an address to bytes32.
     * @param _addr The address to convert.
     * @return The bytes32 representation of the address.
     */
    function toBytes32(address _addr) internal pure returns (bytes32) {
        return bytes32(uint256(uint160(_addr)));
    }
}
