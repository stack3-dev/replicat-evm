// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {LibAsset} from "../libraries/LibAsset.sol";
import {AssetType} from "./AssetType.sol";

using LibAsset for Asset global;

struct Asset {
    AssetType type_;
    uint256 chainBid; // If the bridged asset is an 'XFT' or 'XNFT', ensure that the chainBid is set to '0'.
    address address_;
    bytes metadata; // ex: MetadataFT.encode()
}
