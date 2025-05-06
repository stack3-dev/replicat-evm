// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {Asset} from "../types/Asset.sol";
import {CREATE3} from "../vendors/CREATE3.sol";

/// @custom:security-contact contact@stack3.dev
library LibAsset {
    /// @notice Hashes the asset data
    /// @param asset the asset data
    /// @return the hash
    function hash(Asset memory asset) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    uint8(asset.type_),
                    asset.chainBid,
                    asset.address_,
                    asset.metadata
                )
            );
    }

    /// @notice Compute the replica address using CREATE3
    /// @dev using asset hash as salt
    /// @param asset the asset data
    function computeReplicaAddress(
        Asset memory asset
    ) internal view returns (address) {
        return computeReplicaAddress(hash(asset));
    }

    /// @notice Compute the replica address using CREATE3
    /// @dev using asset hash as salt
    /// @param assetHash the asset hash
    function computeReplicaAddress(
        bytes32 assetHash
    ) internal view returns (address) {
        return CREATE3.predictDeterministicAddress(assetHash);
    }
}
