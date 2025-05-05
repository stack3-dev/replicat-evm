// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity 0.8.28;

import {ERC721, IERC165} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {ERC721Burnable} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import {RNFTCore, IXNFT} from "./RNFTCore.sol";
import {Asset} from "../../types/Asset.sol";
import {MetadataNFT, LibMetadataNFT} from "../../types/MetadataNFT.sol";

/// @title RNFT
/// @author stack3
/// @notice The ERC721 replica contract
/// @custom:security-contact contact@stack3.dev
contract RNFT is RNFTCore, ERC721, ERC721Burnable {
    string private constant NAME_SUFFIX = " (replicaT)";

    string private _baseURI_;

    event BaseURIChanged(string baseURI, address indexed bridge);

    error RNFT_InvalidTokenOwner(uint256 tokenId, address owner);

    /// @notice Constructor
    /// @param asset the asset data
    /// @param metadata the ERC721 metadata
    /// @param bridgeAddress  the local bridge address
    constructor(Asset memory asset, MetadataNFT memory metadata, address bridgeAddress, string memory baseURI)
        RNFTCore(asset, bridgeAddress)
        ERC721(metadata.name, metadata.symbol)
        ERC721Burnable()
    {
        _baseURI_ = baseURI;
    }

    /// @inheritdoc IXNFT
    function crosschainBurn(address from, uint256 tokenId) external override onlyBridge {
        // verify the token ownership
        if (_ownerOf(tokenId) != from) {
            revert RNFT_InvalidTokenOwner(tokenId, from);
        }

        _burn(tokenId);

        emit CrosschainBurn(from, tokenId, msg.sender);
    }

    /// @inheritdoc IXNFT
    function crosschainMint(address to, uint256 tokenId) external override onlyBridge {
        _safeMint(to, tokenId);

        emit CrosschainMint(to, tokenId, msg.sender);
    }

    /// @inheritdoc ERC721
    function name() public view override returns (string memory) {
        return string.concat(_metadataNFT().name, NAME_SUFFIX);
    }

    /// @inheritdoc ERC721
    function symbol() public view override returns (string memory) {
        return _metadataNFT().symbol;
    }

    /// @notice private function retreive the token metadata
    function _metadataNFT() private view returns (MetadataNFT memory) {
        return LibMetadataNFT.decode(_asset().metadata);
    }

    /// @inheritdoc ERC721
    function _baseURI() internal view override returns (string memory) {
        return _baseURI_;
    }

    /// inheritdoc IXNFT
    function setBaseURI(string memory baseURI) external onlyBridge {
        _baseURI_ = baseURI;

        emit BaseURIChanged(baseURI, msg.sender);
    }

    /// @inheritdoc ERC721
    function supportsInterface(bytes4 _interfaceId) public view override(ERC721, RNFTCore) returns (bool) {
        return ERC721.supportsInterface(_interfaceId) || RNFTCore.supportsInterface(_interfaceId);
    }
}
