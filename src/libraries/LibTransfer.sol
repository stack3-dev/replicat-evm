// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {Transfer} from "../types/Transfer.sol";

/// @custom:security-contact contact@stack3.dev
library LibTransfer {
    bytes32 private constant TRANSFER_TYPEHASH =
        keccak256("Transfer(uint8 assetType,bytes32 assetHash,address from,bytes32 to,bytes params,uint256 nonce)");

    /// @notice Hashes the transfer data
    /// @param transfer the transfer data
    /// @return the hash
    function hash(Transfer memory transfer) internal pure returns (bytes32) {
        return keccak256(
            abi.encode(
                TRANSFER_TYPEHASH,
                uint8(transfer.assetType),
                transfer.assetHash,
                transfer.from,
                transfer.to,
                keccak256(transfer.params),
                transfer.nonce
            )
        );
    }
}
