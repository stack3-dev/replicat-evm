// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {Asset, AssetType} from "../../types/Asset.sol";

/// @title IReplicaFactory
/// @author stack3
/// @notice The Replica Factory interface
/// @custom:security-contact contact@stack3.dev
interface IReplicaFactory {
    event ReplicaCreated(bytes32 indexed hash, address indexed address_, address indexed creator, Asset assetData);

    event ReplicaAdapterCreated(
        bytes32 indexed hash, address indexed address_, address indexed creator, Asset assetData
    );

    error ReplicaFactory_AssetClassNotSupported(AssetType assetType);

    /// @notice Create a replica of the asset on the local chain.
    /// @param asset the asset data.
    /// @param extraArgs the extra arguments to pass to the replica.
    function createReplica(Asset calldata asset, bytes calldata extraArgs) external payable returns (address);

    /// @notice Create a replica adapter of the asset on the local chain.
    /// @param asset the asset data.
    function createReplicaAdapter(Asset calldata asset) external payable returns (address);
}
