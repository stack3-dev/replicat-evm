// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {MessageTransfer} from "../types/MessageTransfer.sol";
import {AssetType} from "../types/AssetType.sol";

/// @custom:security-contact contact@stack3.dev
library LibMessageTransfer {
    function encode(MessageTransfer memory messageTransfer) internal pure returns (bytes memory) {
        return abi.encode(
            uint8(messageTransfer.assetType),
            messageTransfer.assetHash,
            messageTransfer.to,
            messageTransfer.params,
            messageTransfer.nonce
        );
    }

    function decode(bytes memory data) internal pure returns (MessageTransfer memory) {
        (uint8 assetType, bytes32 assetHash, address to, bytes memory params, uint256 nonce) =
            abi.decode(data, (uint8, bytes32, address, bytes, uint256));
        return MessageTransfer(AssetType(assetType), assetHash, to, params, nonce);
    }
}
