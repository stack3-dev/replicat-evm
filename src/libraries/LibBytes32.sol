// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

/// @custom:security-contact contact@stack3.dev
library LibBytes32 {
    bytes16 private constant HEX_DIGITS = "0123456789abcdef";

    /**
     * @dev Converts bytes32 to an address.
     * @param _b The bytes32 value to convert.
     * @return The address representation of bytes32.
     */
    function toAddress(bytes32 _b) internal pure returns (address) {
        return address(uint160(uint256(_b)));
    }

    function toHex16(bytes16 data) internal pure returns (bytes32 result) {
        result = (bytes32(data) & 0xFFFFFFFFFFFFFFFF000000000000000000000000000000000000000000000000)
            | ((bytes32(data) & 0x0000000000000000FFFFFFFFFFFFFFFF00000000000000000000000000000000) >> 64);
        result = (result & 0xFFFFFFFF000000000000000000000000FFFFFFFF000000000000000000000000)
            | ((result & 0x00000000FFFFFFFF000000000000000000000000FFFFFFFF0000000000000000) >> 32);
        result = (result & 0xFFFF000000000000FFFF000000000000FFFF000000000000FFFF000000000000)
            | ((result & 0x0000FFFF000000000000FFFF000000000000FFFF000000000000FFFF00000000) >> 16);
        result = (result & 0xFF000000FF000000FF000000FF000000FF000000FF000000FF000000FF000000)
            | ((result & 0x00FF000000FF000000FF000000FF000000FF000000FF000000FF000000FF0000) >> 8);
        result = ((result & 0xF000F000F000F000F000F000F000F000F000F000F000F000F000F000F000F000) >> 4)
            | ((result & 0x0F000F000F000F000F000F000F000F000F000F000F000F000F000F000F000F00) >> 8);
        result = bytes32(
            0x3030303030303030303030303030303030303030303030303030303030303030 + uint256(result)
                + (
                    ((uint256(result) + 0x0606060606060606060606060606060606060606060606060606060606060606) >> 4)
                        & 0x0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F
                ) * 7
        );
    }

    function toHexString(bytes32 data) internal pure returns (string memory) {
        return string(abi.encodePacked("0x", toHex16(bytes16(data)), toHex16(bytes16(data << 128))));
    }
}
