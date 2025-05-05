// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {IReplica} from "../assets/interfaces/IReplica.sol";
import {IXFT} from "../assets/interfaces/IXFT.sol";
import {IXNFT} from "../assets/interfaces/IXNFT.sol";
import {TransferParamsFT, LibTransferParamsFT} from "../types/TransferParamsFT.sol";
import {TransferParamsNFT, LibTransferParamsNFT} from "../types/TransferParamsNFT.sol";
import {AssetType} from "../types/AssetType.sol";
import {LibMath} from "./LibMath.sol";
import {LibBytes32} from "./LibBytes32.sol";

/// @custom:security-contact contact@stack3.dev
library LibReplica {
    using LibMath for uint256;
    using LibBytes32 for bytes32;

    error LibReplica_InvalidAssetType(AssetType assetClass);
    error LibReplica_InvalidTransferAmount(uint256 amount, uint256 decimals, uint256 rest);

    /// @notice Crosschain mint the asset to the recipient
    /// @param replica the replica
    /// @param to the recipient
    /// @param params the mint params
    function crosschainMint(IReplica replica, AssetType assetType, address to, bytes memory params) internal {
        if (assetType == AssetType.FT || assetType == AssetType.XFT) {
            _crosschainMintXFT(IXFT(address(replica)), to, LibTransferParamsFT.decode(params));
        } else if (assetType == AssetType.NFT || assetType == AssetType.XNFT) {
            _crosschainMintXNFT(IXNFT(address(replica)), to, LibTransferParamsNFT.decode(params));
        } else {
            revert LibReplica_InvalidAssetType(assetType);
        }
    }

    /// @notice Crosschain burn the asset from the sender
    /// @param replica the replica
    /// @param from the sender
    /// @param params the burn params
    function crosschainBurn(IReplica replica, AssetType assetType, address from, bytes memory params) internal {
        if (assetType == AssetType.FT || assetType == AssetType.XFT) {
            _crosschainBurnXFT(IXFT(address(replica)), from, LibTransferParamsFT.decode(params));
        } else if (assetType == AssetType.NFT || assetType == AssetType.XNFT) {
            _crosschainBurnXNFT(IXNFT(address(replica)), from, LibTransferParamsNFT.decode(params));
        } else {
            revert LibReplica_InvalidAssetType(assetType);
        }
    }

    /// @notice internal crosschain mint for fungible tokens
    function _crosschainMintXFT(IXFT token, address to, TransferParamsFT memory params) private {
        // Convert the amount to the token's decimals
        uint8 decimals = token.decimals();
        (uint256 amount,) = params.amount.toDecimals(params.decimals, decimals);

        token.crosschainMint(to, amount);
    }

    /// @notice internal crosschain burn for fungible tokens
    function _crosschainBurnXFT(IXFT token, address from, TransferParamsFT memory params) private {
        // Convert the amount to the token's decimals
        uint8 decimals = token.decimals();
        (uint256 amount, uint256 rest) = params.amount.toDecimals(params.decimals, decimals);

        if (rest > 0) {
            revert LibReplica_InvalidTransferAmount(params.amount, params.decimals, rest);
        }

        token.crosschainBurn(from, amount);
    }

    /// @notice internal crosschain mint for non-fungible tokens
    function _crosschainMintXNFT(IXNFT token, address to, TransferParamsNFT memory params) private {
        token.crosschainMint(to, params.tokenId);
    }

    /// @notice internal crosschain burn for non-fungible tokens
    function _crosschainBurnXNFT(IXNFT token, address from, TransferParamsNFT memory params) private {
        token.crosschainBurn(from, params.tokenId);
    }
}
