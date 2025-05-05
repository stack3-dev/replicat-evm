// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {CREATE3} from "../vendors/CREATE3.sol";
import {IBridge} from "../bridge/interfaces/IBridge.sol";
import {Asset, AssetType} from "../types/Asset.sol";
import {ERC20Adapter} from "../assets/ft/ERC20Adapter.sol";
import {ERC721Adapter} from "../assets/nft/ERC721Adapter.sol";
import {XFTAdapter} from "../assets/ft/XFTAdapter.sol";
import {XNFTAdapter} from "../assets/nft/XNFTAdapter.sol";
import {LibMetadataFT} from "../types/MetadataFT.sol";
import {LibMetadataNFT} from "../types/MetadataNFT.sol";
import {LibBytes} from "./LibBytes.sol";
import {LibBytes32} from "./LibBytes32.sol";

/// @custom:security-contact contact@stack3.dev
library LibAssetCreateReplicaAdapter {
    using LibBytes for bytes;
    using LibBytes32 for bytes32;

    error LibAssetCreateReplicaAdapter__UnsupportedAssetType(AssetType type_);
    error LibAssetCreateReplicaAdapter__InvalidChainBid(uint256 currentChainBid, uint256 expectedChainBid);
    error LibAssetCreateReplicaAdapter_InvalidMetadata(bytes currentMetadata, bytes expectedMetadata);

    /// @notice Create a replica adapter contract using CREATE3
    /// @dev using asset hash as salt
    /// @param asset the asset data
    /// @param bridge the bridge address
    /// @return the replica address
    function createReplicaAdapter(Asset memory asset, IBridge bridge) public returns (address) {
        _validateAsset(asset, bridge);

        bytes32 salt = asset.hash();
        return CREATE3.deployDeterministic(_bytecode(asset, address(bridge)), salt);
    }

    /// @notice Validate the chain bid
    function _validateAsset(Asset memory asset, IBridge bridge) private view {
        uint16 chainBid = bridge.chainBid();
        if (asset.type_ == AssetType.FT) {
            _validateAssetChainBid(asset, chainBid);
            _validateFTMetadata(asset);
        } else if (asset.type_ == AssetType.NFT) {
            _validateAssetChainBid(asset, chainBid);
            _validateNFTMetadata(asset);
        } else if (asset.type_ == AssetType.XFT) {
            _validateAssetChainBid(asset, 0);
            _validateFTMetadata(asset);
        } else if (asset.type_ == AssetType.XNFT) {
            _validateAssetChainBid(asset, 0);
            _validateNFTMetadata(asset);
        } else {
            revert LibAssetCreateReplicaAdapter__UnsupportedAssetType(asset.type_);
        }
    }

    /// @notice Validate the asset chain bid
    function _validateAssetChainBid(Asset memory asset, uint256 expectedChainBid) private pure {
        if (asset.chainBid != expectedChainBid) {
            revert LibAssetCreateReplicaAdapter__InvalidChainBid(asset.chainBid, expectedChainBid);
        }
    }

    /// @notice Validate the FT metadata
    function _validateFTMetadata(Asset memory asset) private view {
        bytes memory metadataReaded = LibMetadataFT.tryRead(asset.address_).encode();

        if (!asset.metadata.equal(metadataReaded)) {
            revert LibAssetCreateReplicaAdapter_InvalidMetadata(asset.metadata, metadataReaded);
        }
    }

    /// @notice Validate the NFT metadata
    function _validateNFTMetadata(Asset memory asset) private view {
        bytes memory metadataReaded = LibMetadataNFT.tryRead(asset.address_).encode();

        if (!asset.metadata.equal(metadataReaded)) {
            revert LibAssetCreateReplicaAdapter_InvalidMetadata(asset.metadata, metadataReaded);
        }
    }

    /// @notice Compute the replica bytecode
    function _bytecode(Asset memory asset, address bridge) private pure returns (bytes memory) {
        if (asset.type_ == AssetType.FT) {
            return _bytecode_ERC20Adapter(asset, bridge);
        } else if (asset.type_ == AssetType.NFT) {
            return _bytecode_ERC721Adapter(asset, bridge);
        } else if (asset.type_ == AssetType.XFT) {
            return _bytecode_XFTAdapter(asset, bridge);
        } else if (asset.type_ == AssetType.XNFT) {
            return _bytecode_XNFTAdapter(asset, bridge);
        } else {
            revert LibAssetCreateReplicaAdapter__UnsupportedAssetType(asset.type_);
        }
    }

    /// @notice Compute the ERC20Adapter bytecode
    function _bytecode_ERC20Adapter(Asset memory asset, address bridge) private pure returns (bytes memory) {
        return abi.encodePacked(type(ERC20Adapter).creationCode, abi.encode(asset, bridge));
    }

    /// @notice Compute the ERC721Adapter bytecode
    function _bytecode_ERC721Adapter(Asset memory asset, address bridge) private pure returns (bytes memory) {
        return abi.encodePacked(type(ERC721Adapter).creationCode, abi.encode(asset, bridge));
    }

    /// @notice Compute the XFTAdapter bytecode
    function _bytecode_XFTAdapter(Asset memory asset, address bridge) private pure returns (bytes memory) {
        return abi.encodePacked(type(XFTAdapter).creationCode, abi.encode(asset, bridge));
    }

    /// @notice Compute the XNFTAdapter bytecode
    function _bytecode_XNFTAdapter(Asset memory asset, address bridge) private pure returns (bytes memory) {
        return abi.encodePacked(type(XNFTAdapter).creationCode, abi.encode(asset, bridge));
    }
}
