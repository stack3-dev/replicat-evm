// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity 0.8.28;

import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {RNFTCore, IXNFT} from "./RNFTCore.sol";
import {LibBytes32} from "../../libraries/LibBytes32.sol";
import {Asset, AssetType} from "../../types/Asset.sol";

/// @title XNFTAdapter
/// @author stack3
/// @notice The Crosschain XNFT adapter contract
/// @dev The XNFTAdapter contract is used to connect an existing XNFT token to the bridge.
/// @dev the XNFT token must allow the bridge adapter contract to call crosschainMint and crosschainBurn.
/// @custom:security-contact contact@stack3.dev
contract XNFTAdapter is RNFTCore {
    using LibBytes32 for bytes32;

    IXNFT internal immutable _innerToken;

    /// @notice Constructor
    /// @param asset the asset data
    /// @param bridgeAddress  the local bridge address
    constructor(Asset memory asset, address bridgeAddress) RNFTCore(asset, bridgeAddress) {
        _innerToken = IXNFT(asset.address_);
    }

    /// @inheritdoc IXNFT
    function crosschainBurn(address from, uint256 tokenId) external override onlyBridge {
        _innerToken.crosschainBurn(from, tokenId);

        emit CrosschainBurn(from, tokenId, msg.sender);
    }

    /// @inheritdoc IXNFT
    function crosschainMint(address to, uint256 tokenId) external override onlyBridge {
        _innerToken.crosschainMint(to, tokenId);

        emit CrosschainMint(to, tokenId, msg.sender);
    }
}
