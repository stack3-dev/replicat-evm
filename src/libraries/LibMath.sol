// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";

/// @custom:security-contact contact@stack3.dev
library LibMath {
    using Math for uint256;

    error LibMath_Overflow();

    /// @dev calculate basis point from value with bpValue. (bp = value * bpValue / 100_00)
    /// @param value the value input
    /// @param bpValue  the bp input (100_00 = 100%)
    function bp(uint256 value, uint48 bpValue) internal pure returns (uint256) {
        return value.mulDiv(bpValue, 100_00, Math.Rounding.Ceil);
    }

    function inflate(uint256 value, uint48 bpValue) internal pure returns (uint256) {
        (bool success, uint256 result) = value.tryAdd(bp(value, bpValue));
        if (!success) {
            revert LibMath_Overflow();
        }
        return result;
    }

    function beforeInflate(uint256 value, uint48 bpValue) internal pure returns (uint256) {
        return value.mulDiv(100_00, 100_00 + bpValue, Math.Rounding.Ceil);
    }

    /**
     * @dev Internal function to convert an amount from a decimals into another decimals.
     * e.g. 100 from 2 decimals to 3 decimals will return 1000 rest 0
     * e.g. 100 from 3 decimals to 2 decimals will return 10 rest 0
     * e.g. 101 from 3 decimals to 1 decimals will return 10 rest 1
     * @param fromAmount The amount in the fromDecimals.
     * @param fromDecimals The decimals of the fromAmount.
     * @param toDecimals_ The decimals to convert the amount to.
     * @return toAmount The amount in the toDecimals.
     * @return fromRest The rest of the conversion.
     */
    function toDecimals(uint256 fromAmount, uint8 fromDecimals, uint8 toDecimals_)
        internal
        pure
        returns (uint256 toAmount, uint256 fromRest)
    {
        if (fromDecimals == toDecimals_) {
            return (fromAmount, 0);
        }

        uint256 factor;
        if (fromDecimals > toDecimals_) {
            factor = 10 ** (fromDecimals - toDecimals_);
            fromRest = fromAmount % factor;
            toAmount = fromAmount / factor;
        } else {
            factor = 10 ** (toDecimals_ - fromDecimals);
            (bool success, uint256 result) = fromAmount.tryMul(factor);
            if (!success) {
                revert LibMath_Overflow();
            }
            toAmount = result;
        }
    }
}
