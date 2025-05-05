// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {IERC165} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

/// @title IXNFT
/// @author stack3
/// @notice A crosschain NFT interface
/// @custom:security-contact contact@stack3.dev
interface IXNFT is IERC165 {
    event CrosschainMint(address indexed to, uint256 tokenId, address indexed sender);

    event CrosschainBurn(address indexed from, uint256 tokenId, address indexed sender);

    /// @notice Mint the asset on the local chain.
    /// @param to the address to mint the asset to.
    /// @param tokenId the token id to mint.
    function crosschainMint(address to, uint256 tokenId) external;

    /// @notice Burn the asset on the local chain.
    /// @param from the address to burn the asset from.
    /// @param tokenId the token id to burn.
    function crosschainBurn(address from, uint256 tokenId) external;
}
