// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {TransferParamsFT} from "../types/TransferParamsFT.sol";

/// @custom:security-contact contact@stack3.dev
library LibTransferParamsFT {
    function encode(TransferParamsFT memory metadata) internal pure returns (bytes memory) {
        return abi.encode(metadata.amount, metadata.decimals);
    }

    function decode(bytes memory data) internal pure returns (TransferParamsFT memory) {
        (uint256 amount, uint8 decimals) = abi.decode(data, (uint256, uint8));
        return TransferParamsFT(amount, decimals);
    }
}
