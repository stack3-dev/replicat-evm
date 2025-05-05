// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {TransferParamsNFT} from "../types/TransferParamsNFT.sol";

/// @custom:security-contact contact@stack3.dev
library LibTransferParamsNFT {
    function encode(TransferParamsNFT memory metadata) internal pure returns (bytes memory) {
        return abi.encode(metadata.tokenId);
    }

    function decode(bytes memory data) internal pure returns (TransferParamsNFT memory) {
        uint256 tokenId = abi.decode(data, (uint256));
        return TransferParamsNFT(tokenId);
    }
}
