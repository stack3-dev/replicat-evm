// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

/// @custom:security-contact contact@stack3.dev
library LibBytes {
    /**
     * @dev Returns true if the two bytes are equal.
     */
    function equal(bytes memory a, bytes memory b) internal pure returns (bool) {
        return a.length == b.length && keccak256(a) == keccak256(b);
    }
}
