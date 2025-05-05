// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {AssetType} from "./AssetType.sol";
import {LibTransfer} from "../libraries/LibTransfer.sol";

using LibTransfer for Transfer global;

/// @notice Transfer structure used to describe a cross-chain transfer.
struct Transfer {
    AssetType assetType; // FT or NFT
    bytes32 assetHash; // see LibAsset.hash()
    address from; // sender address
    address to; // recipient address
    uint16 chainBid; // the target chain bid
    bytes params; // e.g LibTransferParamsFT.encode() or LibTransferParamsNFT.encode()
    uint256 nonce; // the nonce of the message
}
