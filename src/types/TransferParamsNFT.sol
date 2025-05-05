// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {LibTransferParamsNFT} from "../libraries/LibTransferParamsNFT.sol";

using LibTransferParamsNFT for TransferParamsNFT global;

/// @notice TransferParamsNFT structure.
struct TransferParamsNFT {
    uint256 tokenId;
}
