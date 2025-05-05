// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {IWormholeRelayer, VaaKey, MessageKey} from "@wormhole/interfaces/IWormholeRelayer.sol";
import {IWormholeReceiver} from "@wormhole/interfaces/IWormholeReceiver.sol";
import {LibAddress} from "../../src/libraries/LibAddress.sol";

contract WormholeRelayerMock is IWormholeRelayer {
    using LibAddress for address;

    struct Message {
        uint16 targetChain;
        address targetAddress;
        bytes payload;
        uint256 receiverValue;
        uint256 gasLimit;
    }

    uint256 public cost = 0;
    uint64 public sequenceCounter = 1;
    mapping(uint256 sequence => Message message) public messages;

    constructor() {}

    function setCost(uint256 _cost) external {
        cost = _cost;
    }

    function sendPayloadToEvm(
        uint16 targetChain,
        address targetAddress,
        bytes memory payload,
        uint256 receiverValue,
        uint256 gasLimit
    ) external payable returns (uint64 sequence) {
        messages[sequenceCounter] = Message({
            targetChain: targetChain,
            targetAddress: targetAddress,
            payload: payload,
            receiverValue: receiverValue,
            gasLimit: gasLimit
        });

        sequence = sequenceCounter;
        sequenceCounter++;
    }

    function lastSequence() public view returns (uint64) {
        return sequenceCounter - 1;
    }

    function lastSent() public view returns (Message memory) {
        return messages[lastSequence()];
    }

    function mockReceive(IWormholeReceiver receiver, bytes memory payload, address sourceAddress, uint16 sourceChain)
        external
    {
        bytes[] memory empty = new bytes[](0);

        receiver.receiveWormholeMessages(payload, empty, sourceAddress.toBytes32(), sourceChain, keccak256(payload));
    }

    function quoteEVMDeliveryPrice(uint16 targetChain, uint256 receiverValue, uint256 gasLimit)
        external
        view
        override
        returns (uint256 nativePriceQuote, uint256 targetChainRefundPerGasUnused)
    {
        return (cost, 0);
    }

    // UNUSED  FUNCTIONS

    function getRegisteredWormholeRelayerContract(uint16 chainId) external view override returns (bytes32) {
        revert("Not implemented");
    }

    function deliveryAttempted(bytes32 deliveryHash) external view override returns (bool attempted) {
        revert("Not implemented");
    }

    function deliverySuccessBlock(bytes32 deliveryHash) external view override returns (uint256 blockNumber) {
        revert("Not implemented");
    }

    function deliveryFailureBlock(bytes32 deliveryHash) external view override returns (uint256 blockNumber) {
        revert("Not implemented");
    }

    function deliver(
        bytes[] memory encodedVMs,
        bytes memory encodedDeliveryVAA,
        address payable relayerRefundAddress,
        bytes memory deliveryOverrides
    ) external payable override {
        revert("Not implemented");
    }

    function sendPayloadToEvm(
        uint16 targetChain,
        address targetAddress,
        bytes memory payload,
        uint256 receiverValue,
        uint256 gasLimit,
        uint16 refundChain,
        address refundAddress
    ) external payable override returns (uint64 sequence) {
        revert("Not implemented");
    }

    function sendVaasToEvm(
        uint16 targetChain,
        address targetAddress,
        bytes memory payload,
        uint256 receiverValue,
        uint256 gasLimit,
        VaaKey[] memory vaaKeys
    ) external payable override returns (uint64 sequence) {
        revert("Not implemented");
    }

    function sendVaasToEvm(
        uint16 targetChain,
        address targetAddress,
        bytes memory payload,
        uint256 receiverValue,
        uint256 gasLimit,
        VaaKey[] memory vaaKeys,
        uint16 refundChain,
        address refundAddress
    ) external payable override returns (uint64 sequence) {
        revert("Not implemented");
    }

    function sendToEvm(
        uint16 targetChain,
        address targetAddress,
        bytes memory payload,
        uint256 receiverValue,
        uint256 paymentForExtraReceiverValue,
        uint256 gasLimit,
        uint16 refundChain,
        address refundAddress,
        address deliveryProviderAddress,
        VaaKey[] memory vaaKeys,
        uint8 consistencyLevel
    ) external payable override returns (uint64 sequence) {
        revert("Not implemented");
    }

    function sendToEvm(
        uint16 targetChain,
        address targetAddress,
        bytes memory payload,
        uint256 receiverValue,
        uint256 paymentForExtraReceiverValue,
        uint256 gasLimit,
        uint16 refundChain,
        address refundAddress,
        address deliveryProviderAddress,
        MessageKey[] memory messageKeys,
        uint8 consistencyLevel
    ) external payable override returns (uint64 sequence) {
        revert("Not implemented");
    }

    function send(
        uint16 targetChain,
        bytes32 targetAddress,
        bytes memory payload,
        uint256 receiverValue,
        uint256 paymentForExtraReceiverValue,
        bytes memory encodedExecutionParameters,
        uint16 refundChain,
        bytes32 refundAddress,
        address deliveryProviderAddress,
        VaaKey[] memory vaaKeys,
        uint8 consistencyLevel
    ) external payable override returns (uint64 sequence) {
        revert("Not implemented");
    }

    function send(
        uint16 targetChain,
        bytes32 targetAddress,
        bytes memory payload,
        uint256 receiverValue,
        uint256 paymentForExtraReceiverValue,
        bytes memory encodedExecutionParameters,
        uint16 refundChain,
        bytes32 refundAddress,
        address deliveryProviderAddress,
        MessageKey[] memory messageKeys,
        uint8 consistencyLevel
    ) external payable override returns (uint64 sequence) {
        revert("Not implemented");
    }

    function resendToEvm(
        VaaKey memory deliveryVaaKey,
        uint16 targetChain,
        uint256 newReceiverValue,
        uint256 newGasLimit,
        address newDeliveryProviderAddress
    ) external payable override returns (uint64 sequence) {
        revert("Not implemented");
    }

    function resend(
        VaaKey memory deliveryVaaKey,
        uint16 targetChain,
        uint256 newReceiverValue,
        bytes memory newEncodedExecutionParameters,
        address newDeliveryProviderAddress
    ) external payable override returns (uint64 sequence) {
        revert("Not implemented");
    }

    function quoteEVMDeliveryPrice(
        uint16 targetChain,
        uint256 receiverValue,
        uint256 gasLimit,
        address deliveryProviderAddress
    ) external view override returns (uint256 nativePriceQuote, uint256 targetChainRefundPerGasUnused) {
        revert("Not implemented");
    }

    function quoteDeliveryPrice(
        uint16 targetChain,
        uint256 receiverValue,
        bytes memory encodedExecutionParameters,
        address deliveryProviderAddress
    ) external view override returns (uint256 nativePriceQuote, bytes memory encodedExecutionInfo) {
        revert("Not implemented");
    }

    function quoteNativeForChain(uint16 targetChain, uint256 currentChainAmount, address deliveryProviderAddress)
        external
        view
        override
        returns (uint256 targetChainAmount)
    {
        revert("Not implemented");
    }

    function getDefaultDeliveryProvider() external view override returns (address deliveryProvider) {
        revert("Not implemented");
    }
}
