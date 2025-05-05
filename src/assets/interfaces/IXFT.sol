// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {IERC7802, IERC165} from "@interop-lib/interfaces/IERC7802.sol";

/// @title IXFT
/// @author stack3
/// @notice A crosschain fungible token interface
/// @dev The interface is used by the bridge to mint and burn the replicated asset. The interface extends the standard crosschain IERC7802 for ERC20.
/// @custom:security-contact contact@stack3.dev
interface IXFT is IERC7802 {
    /// @notice The number of decimals the asset uses - e.g. 18, means to divide the asset amount by 10^18
    /// @dev Ensure the asset expose decimals allowing the bridge to use floating point numbers for crosschain transfers
    function decimals() external view returns (uint8);
}
