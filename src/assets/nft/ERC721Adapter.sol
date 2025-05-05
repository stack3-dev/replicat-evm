// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity 0.8.28;

import {RNFTCore} from "./RNFTCore.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {ERC721Holder} from "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import {IXNFT} from "../interfaces/IXNFT.sol";
import {LibBytes32} from "../../libraries/LibBytes32.sol";
import {Asset} from "../../types/Asset.sol";

/// @title rNFT
/// @author stack3
/// @notice The ERC721 replica contract
/// @custom:security-contact contact@stack3.dev
contract ERC721Adapter is RNFTCore, ERC721Holder {
    using LibBytes32 for bytes32;

    IERC721 internal immutable _innerToken;

    /// @notice Constructor
    /// @param asset the asset data
    /// @param bridgeAddress  the local bridge address
    constructor(Asset memory asset, address bridgeAddress) RNFTCore(asset, bridgeAddress) {
        _innerToken = IERC721(asset.address_);
    }

    /// @inheritdoc IXNFT
    function crosschainBurn(address from, uint256 tokenId) external override onlyBridge {
        _innerToken.safeTransferFrom(from, address(this), tokenId);

        emit CrosschainBurn(from, tokenId, msg.sender);
    }

    /// @inheritdoc IXNFT
    function crosschainMint(address to, uint256 tokenId) external override onlyBridge {
        _innerToken.safeTransferFrom(address(this), to, tokenId);

        emit CrosschainMint(to, tokenId, msg.sender);
    }
}
