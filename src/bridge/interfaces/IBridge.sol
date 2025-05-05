// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {Transfer} from "../../types/Transfer.sol";
import {MessageTransfer} from "../../types/MessageTransfer.sol";

/// @title IBridge
/// @author stack3
/// @notice The Bridge interface
/// @custom:security-contact contact@stack3.dev
interface IBridge {
    struct Permit {
        address token;
        uint256 value;
        uint256 deadline;
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    event Transfered(bytes32 indexed transferHash, Transfer data);
    event TransferedCrosschain(bytes32 indexed messageHash, MessageTransfer data);
    event TransferReverted(bytes32 indexed transferHash, Transfer data);

    error Bridge_AssetNotFound(bytes32 assetHash);
    error Bridge_TransferNotFound(bytes32 transferHash);
    error Bridge_TransferNotRevertable(bytes32 transferHash);
    error Bridge_TransferAlreadyProcessed(bytes32 transferHash);
    error Bridge_TransferAlreadyReverted(bytes32 transferHash);
    error Bridge_InvalidChainBid(uint256 chainBid);
    error Bridge_UnauthorizedRelayer(address relayer);
    error Bridge_RelayerNotFound(bytes4 relayerClass);
    error Bridge_InvalidSignature(address signer, bytes32 digest, bytes signature);

    /// @notice Get the chain bridge ID.
    /// @return The chain bridge ID.
    function chainBid() external view returns (uint16);

    /// @notice Transfer crosschain assets through the bridge.
    /// @dev The asset approval must be done before calling this function.
    /// @dev The asset must be replicated on the destination chain.
    /// @dev The relayer must be registered on both local and destination bridges.
    /// @param data The transfer data.
    /// @param signature The optional signature. Only required if sender is not the caller.
    function transfer(Transfer calldata data, bytes calldata signature)
        external
        payable
        returns (bytes32 transferHash);

    /// @notice Transfer crosschain assets through the bridge with permit.
    /// @dev The asset approval can be done through permit.
    /// @dev The asset must be replicated on the destination chain.
    /// @dev The relayer must be registered on both local and destination bridges.
    /// @param data The transfer data.
    /// @param signature The optional signature. Only required if sender is not the caller.
    /// @param permit The permit data.
    function transferWithPermit(Transfer calldata data, bytes calldata signature, Permit calldata permit)
        external
        payable
        returns (bytes32 transferHash);

    /// @notice Quote the gas cost for a crosschain transfer. It includes the bridge transfer and the relayer execution costs.
    /// @param targetChainBid The target chain ID.
    /// @return The amount of gas required for the transfer.
    function quoteTransfer(uint16 targetChainBid) external view returns (uint256);

    /**
     * @dev get the transfer sequence number for a given transfer hash
     * @param transferHash The transfer hash
     * @return The transfer sequence number
     */
    function getTransferSequence(bytes32 transferHash) external view returns (uint64);
}
