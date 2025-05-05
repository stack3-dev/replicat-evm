// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {LibMessageTransfer} from "../libraries/LibMessageTransfer.sol";
import {AssetType} from "./AssetType.sol";

using LibMessageTransfer for MessageTransfer global;

struct MessageTransfer {
    AssetType assetType; // FT or NFT
    bytes32 assetHash; // see LibAsset.hash()
    address to; // recipient address
    bytes params; // encoded transfer parameters. see LibTransferParamsFT.encode() or LibTransferParamsNFT.encode()
    uint256 nonce; // the nonce of the message
}
