// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {CREATE3} from "../vendors/CREATE3.sol";
import {IBridge} from "../bridge/interfaces/IBridge.sol";
import {Asset, AssetType} from "../types/Asset.sol";
import {MetadataFT, LibMetadataFT} from "../types/MetadataFT.sol";
import {MetadataNFT, LibMetadataNFT} from "../types/MetadataNFT.sol";
import {RFT} from "../assets/FT/RFT.sol";
import {RNFT} from "../assets/NFT/RNFT.sol";

/// @custom:security-contact contact@stack3.dev
library LibAssetCreateReplica {
    error LibAssetCreateReplica__UnsupportedAssetType(AssetType type_);
    error LibAssetCreateReplica__InvalidChainBid(uint256 chainBid);

    /// @notice Create a replica contract using CREATE3
    /// @dev using asset hash as salt
    /// @param asset the asset data
    /// @param bridge the bridge address
    /// @param extraArgs the asset data
    /// @return the replica address
    function createReplica(Asset memory asset, IBridge bridge, bytes memory extraArgs) public returns (address) {
        _validateAsset(asset, bridge);

        bytes32 salt = asset.hash();
        return CREATE3.deployDeterministic(_bytecode(asset, address(bridge), extraArgs), salt);
    }

    /// @notice Validate the chain bid
    function _validateAsset(Asset memory asset, IBridge bridge) private view {
        uint16 chainBid = bridge.chainBid();

        if (asset.chainBid == chainBid) {
            revert LibAssetCreateReplica__InvalidChainBid(asset.chainBid);
        }
    }

    /// @notice Compute the replica bytecode
    function _bytecode(Asset memory asset, address bridge, bytes memory extraArgs)
        private
        pure
        returns (bytes memory)
    {
        if (asset.type_ == AssetType.FT) {
            return _bytecode_RFT(asset, bridge);
        } else if (asset.type_ == AssetType.NFT) {
            return _bytecode_RNFT(asset, bridge, extraArgs);
        } else {
            revert LibAssetCreateReplica__UnsupportedAssetType(asset.type_);
        }
    }

    /// @notice Compute the RFT bytecode
    function _bytecode_RFT(Asset memory asset, address bridge) private pure returns (bytes memory) {
        MetadataFT memory metadata = LibMetadataFT.decode(asset.metadata);

        return abi.encodePacked(type(RFT).creationCode, abi.encode(asset, metadata, bridge));
    }

    /// @notice Compute the RNFT bytecode
    function _bytecode_RNFT(Asset memory asset, address bridge, bytes memory extraArgs)
        private
        pure
        returns (bytes memory)
    {
        MetadataNFT memory metadata = LibMetadataNFT.decode(asset.metadata);

        string memory baseURI = extraArgs.length > 0 ? abi.decode(extraArgs, (string)) : "";

        return abi.encodePacked(type(RNFT).creationCode, abi.encode(asset, metadata, bridge, baseURI));
    }
}
