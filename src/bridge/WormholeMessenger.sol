// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {BitMaps} from "@openzeppelin/contracts/utils/structs/BitMaps.sol";
import {IWormhole} from "@wormhole/interfaces/IWormhole.sol";
import {IWormholeRelayer} from "lib/wormhole-solidity-sdk/src/interfaces/IWormholeRelayer.sol";
import {IWormholeReceiver} from "lib/wormhole-solidity-sdk/src/interfaces/IWormholeReceiver.sol";
import {LibBytes32} from "../libraries/LibBytes32.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";

/// @title WormholeMessenger
/// @notice Abstract contract for sending and receiving messages using the Wormhole protocol.
abstract contract WormholeMessenger is IWormholeReceiver {
    using LibBytes32 for bytes32;
    using BitMaps for BitMaps.BitMap;
    using Address for address;

    /// @dev Gas limit for message delivery.
    uint256 public constant GAS_LIMIT = 250_000;

    /// @notice Wormhole relayer contract.
    IWormholeRelayer private _wormholeRelayer;

    /// @notice BitMap to track handled messages.
    BitMaps.BitMap private _handledMessages;

    /// @dev Error thrown when the Wormhole relayer address is invalid.
    error WormholeMessenger_InvalidWormholeRelayerAddress();

    /// @dev Error thrown when the sender does not provide sufficient funds.
    error WormholeMessenger_InsufficientFunds();

    /// @dev Error thrown when the caller is not authorized.
    error WormholeMessenger_UnauthorizedCaller(address caller);

    /// @dev Error thrown when the foreign relayer address is invalid.
    error WormholeMessenger_InvalidForeignRelayer(address foreignRelayer);

    /// @dev Error thrown when the message has already been handled.
    error WormholeMessenger_MessageAlreadyHandled(bytes32 deliveryHash);

    /// @notice Event emitted when a message is sent.
    /// @param targetChainBid The target chain ID.
    /// @param payload The message payload.
    /// @param sequence The sequence number of the message.
    event WormholeMessageSent(
        uint64 indexed sequence,
        uint16 targetChainBid,
        bytes payload
    );

    /// @notice Event emitted when a message is received.
    /// @param payload The received message payload.
    /// @param sourceChain The source chain ID.
    /// @param deliveryHash The delivery hash of the message.
    event WormholeMessageReceived(
        bytes32 indexed deliveryHash,
        bytes payload,
        uint16 sourceChain
    );

    /// @notice The chain ID of the current chain.
    uint16 private immutable _chainBid_;

    /// @notice Restricts access to the Wormhole relayer contract.
    modifier onlyWormholeRelayer() {
        if (msg.sender != address(_wormholeRelayer)) {
            revert WormholeMessenger_UnauthorizedCaller(msg.sender);
        }
        _;
    }

    /// @notice Constructor to initialize the WormholeMessenger contract.
    /// @param chainBid The chain ID of the current chain.
    /// @param wormholeRelayer_ The address of the Wormhole relayer contract.
    constructor(uint16 chainBid, address wormholeRelayer_) {
        if (wormholeRelayer_ == address(0)) {
            revert WormholeMessenger_InvalidWormholeRelayerAddress();
        }

        _chainBid_ = chainBid;
        _wormholeRelayer = IWormholeRelayer(wormholeRelayer_);
    }

    /// @notice Returns the chain ID of the current chain.
    /// @return The chain ID of the current chain.
    function _chainBid() internal view returns (uint16) {
        return _chainBid_;
    }

    /// @notice Quotes the cost of transmitting a message to a target chain.
    /// @param targetChain The target chain ID.
    /// @return cost The estimated cost of the message transmission.
    function quoteTransmitMessage(
        uint16 targetChain
    ) public view returns (uint256 cost) {
        cost = _quoteTransmitMessage(targetChain);
    }

    /// @dev Internal function to quote the cost of transmitting a message.
    /// @param targetChain The target chain ID.
    /// @return cost The estimated cost of the message transmission.
    function _quoteTransmitMessage(
        uint16 targetChain
    ) internal view returns (uint256 cost) {
        (cost, ) = _wormholeRelayer.quoteEVMDeliveryPrice(
            targetChain,
            0,
            GAS_LIMIT
        );
    }

    /// @dev Internal function to send a message to a target chain.
    /// @param targetChain The target chain ID.
    /// @param payload The message payload.
    /// @param refundAddress The address to refund any excess funds.
    /// @return sequence The sequence number of the message.
    function _sendMessage(
        uint16 targetChain,
        bytes memory payload,
        address refundAddress
    ) internal returns (uint64 sequence) {
        uint256 cost = _quoteTransmitMessage(targetChain);

        if (msg.value < cost) {
            revert WormholeMessenger_InsufficientFunds();
        }

        sequence = _wormholeRelayer.sendPayloadToEvm{value: cost}(
            targetChain,
            address(this),
            payload,
            0,
            GAS_LIMIT
        );

        // refund any excess funds
        if (msg.value > cost) {
            Address.sendValue(payable(refundAddress), msg.value - cost);
        }

        emit WormholeMessageSent(sequence, targetChain, payload);
    }

    /// @notice Handles the receipt of Wormhole messages.
    /// @param payload The received message payload.
    /// @param sourceAddress The source address of the message.
    /// @param sourceChain The source chain ID.
    /// @param deliveryHash The delivery hash of the message.
    function receiveWormholeMessages(
        bytes memory payload,
        bytes[] memory,
        bytes32 sourceAddress,
        uint16 sourceChain,
        bytes32 deliveryHash
    ) public payable override onlyWormholeRelayer {
        // Check if the source address is the expected foreign relayer address
        if (sourceAddress.toAddress() != address(this)) {
            revert WormholeMessenger_InvalidForeignRelayer(
                sourceAddress.toAddress()
            );
        }

        // Check if the delivery hash has already been handled
        if (_handledMessages.get(uint256(deliveryHash))) {
            revert WormholeMessenger_MessageAlreadyHandled(deliveryHash);
        }

        // Mark the delivery hash as handled
        _handledMessages.set(uint256(deliveryHash));

        // Handle the message payload
        _handleMessage(payload);

        emit WormholeMessageReceived(deliveryHash, payload, sourceChain);
    }

    /// @notice Handle a message payload.
    /// @param payload The payload to handle.
    function _handleMessage(bytes memory payload) internal virtual;

    /// @notice Returns the Wormhole relayer contract address.
    /// @return The address of the Wormhole relayer contract.
    function wormholeRelayer() external view returns (IWormholeRelayer) {
        return _wormholeRelayer;
    }
}
