// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

enum AssetType {
    FT, // Fungible Token.
    XFT, // Crosschain Fungible Token allowing ReplicaT Bridge.
    NFT, // Non-Fungible Token.
    XNFT // Crosschain Non-Fungible Token allowing ReplicaT Bridge.

}
