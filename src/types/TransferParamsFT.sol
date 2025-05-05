// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {LibTransferParamsFT} from "../libraries/LibTransferParamsFT.sol";

using LibTransferParamsFT for TransferParamsFT global;

/// @notice TransferParamsFT structure.
struct TransferParamsFT {
    uint256 amount; // the amount of tokens to transfer
    uint8 decimals; // the number of decimals the token uses
}
