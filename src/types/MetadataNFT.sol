// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {LibMetadataNFT} from "../libraries/LibMetadataNFT.sol";

using LibMetadataNFT for MetadataNFT global;

struct MetadataNFT {
    string name; // the name of the token
    string symbol; // the symbol of the token
}
