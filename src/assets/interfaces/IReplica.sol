// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {Asset} from "../../types/Asset.sol";

/// @title IReplica interface
/// @author stack3
/// @notice The Replica interface used to identify the asset replica on foreign chains.
/// @custom:security-contact contact@stack3.dev
interface IReplica {
    /// @notice Returns the asset hash
    function assetHash() external view returns (bytes32);

    /// @notice Return the asset address on origin chain
    function asset() external view returns (Asset memory);

    /// @notice Return the replica bridge address
    function bridgeAddress() external view returns (address);
}
