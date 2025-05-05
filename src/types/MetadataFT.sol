// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {LibMetadataFT} from "../libraries/LibMetadataFT.sol";

using LibMetadataFT for MetadataFT global;

struct MetadataFT {
    string name; // the name of the token
    string symbol; // the symbol of the token
    uint8 decimals; // the number of decimals the token uses
}
