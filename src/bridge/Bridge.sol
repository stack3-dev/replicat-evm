// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IWormhole} from "@wormhole/interfaces/IWormhole.sol";
import {IWormholeRelayer} from "lib/wormhole-solidity-sdk/src/interfaces/IWormholeRelayer.sol";
import {IBridge, BridgeCore, EIP712, IReplica, ReplicaFactory} from "./BridgeCore.sol";
import {RNFT} from "../assets/nft/RNFT.sol";

/// @title Bridge
/// @author stack3
/// @notice The Bridge contract
/// @dev This contract is owned to allow the messengers management and the factory fee management.
/// @custom:security-contact contact@stack3.dev
contract Bridge is BridgeCore, Ownable {
    /// @notice Constructor
    constructor(address initialOwner, uint16 wormholeChainId, address wormholeRelayer)
        BridgeCore(wormholeChainId, wormholeRelayer)
        Ownable(initialOwner)
    {}

    /// @notice Update the RNFT base URI.
    /// @dev allow the owner to update the base URI of a the replica in case of a mistake or a malicious behabior.
    /// @param replica The replica contract.
    /// @param baseURI The base URI.
    function updateRNFTBaseURI(RNFT replica, string memory baseURI) external onlyOwner {
        replica.setBaseURI(baseURI);
    }

    /// @notice Get the chain bid.
    function chainBid() external view returns (uint16) {
        return _chainBid();
    }

    /// @notice Set the replica factory fee.
    /// @dev allow the owner to set the factory fee.
    function setFactoryFee(uint256 fee) external onlyOwner {
        _setFactoryFee(fee);
    }

    /// @notice Withdraw the factory fees.
    /// @dev allow the owner to withdraw the factory fees.
    function withdrawTransferFees(address payable payee) external {
        _withdrawFactoryFees(payee);
    }
}
