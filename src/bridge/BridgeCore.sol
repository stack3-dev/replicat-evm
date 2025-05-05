// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {IERC20Permit} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Permit.sol";
import {EIP712} from "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import {SignatureChecker} from "@openzeppelin/contracts/utils/cryptography/SignatureChecker.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {Context} from "@openzeppelin/contracts/utils/Context.sol";
import {IBridge, Transfer} from "./interfaces/IBridge.sol";
import {IReplica} from "../assets/interfaces/IReplica.sol";
import {WormholeMessenger} from "./WormholeMessenger.sol";
import {ReplicaFactory} from "../assets/ReplicaFactory.sol";
import {MessageTransfer, LibMessageTransfer} from "../types/MessageTransfer.sol";
import {LibReplica} from "../libraries/LibReplica.sol";
import {LibBytes32} from "../libraries/LibBytes32.sol";
import {LibMath} from "../libraries/LibMath.sol";
import {Asset, LibAsset} from "../types/Asset.sol";

/// @title BridgeCore
/// @author stack3
/// @notice The core contract of the bridge
/// @custom:security-contact contact@stack3.dev
abstract contract BridgeCore is IBridge, WormholeMessenger, ReplicaFactory, EIP712, Context {
    using Address for address payable;
    using LibReplica for IReplica;
    using LibBytes32 for bytes32;
    using LibMath for uint256;
    using SignatureChecker for address;

    /**
     *
     */
    /* constant     */

    string private constant EIP712_NAMESPACE = "replicate.stack3";

    string private constant EIP712_VERSION = "1";

    /**
     *
     */
    /* properties   */

    mapping(bytes32 transferHash => uint64 sequence) private _transfers;

    /**
     *
     */
    /* constructor  */

    constructor(uint16 wormholeChainId, address wormholeRelayer)
        ReplicaFactory(this)
        WormholeMessenger(wormholeChainId, wormholeRelayer)
        EIP712(EIP712_NAMESPACE, EIP712_VERSION)
    {}

    /**
     *
     */
    /* User Entry-Point  */

    /// @inheritdoc IBridge
    function transfer(Transfer calldata transfer_, bytes calldata signature)
        external
        payable
        override
        returns (bytes32)
    {
        return _transfer(transfer_, signature);
    }

    /// @inheritdoc IBridge
    function transferWithPermit(Transfer calldata transfer_, bytes calldata signature, Permit calldata permit)
        external
        payable
        override
        returns (bytes32)
    {
        address adapter = LibAsset.computeReplicaAddress(transfer_.assetHash);

        try IERC20Permit(permit.token).permit(
            transfer_.from, adapter, permit.value, permit.deadline, permit.v, permit.r, permit.s
        ) {} catch {}

        return _transfer(transfer_, signature);
    }

    /// @dev Execute transfer from the bridge.
    /// @param transfer_  The transfer data.
    /// @param signature The optional signature of the transfer. If the transfer is not from the sender, the signature must be provided.
    function _transfer(Transfer calldata transfer_, bytes calldata signature) private returns (bytes32 transferHash) {
        transferHash = _hash(transfer_.hash());

        // Validate transfer input
        _validateTransfer(transferHash, transfer_, signature);

        // prevent transfer reentrancy by setting the transfer sequence to max value
        _transfers[transferHash] = type(uint64).max;

        // Perform asset transfer
        _doTransfer(transfer_);

        // Forward transfer to foreign chain
        uint64 sequence = _doForwardCrosschainTransfer(transfer_);

        // update transfer sequence
        _transfers[transferHash] = sequence;

        // Store transfer
        emit Transfered(transferHash, transfer_);
    }

    /// @dev Validate the transfer input.
    /// @dev The transfer must be from the sender or the signature must be provided.
    /// @dev The transfer must not have been processed yet.
    /// @dev The transfer must be from the bridge chain.
    /// @dev The transfer must not be to the bridge chain.
    /// @param transferHash The transfer hash.
    /// @param transfer_ The transfer data.
    /// @param signature The optional signature of the transfer.
    function _validateTransfer(bytes32 transferHash, Transfer calldata transfer_, bytes calldata signature)
        private
        view
    {
        // check transfer input
        if (transfer_.chainBid == _chainBid()) {
            revert Bridge_InvalidChainBid(transfer_.chainBid);
        }
        // check if transfer already processed
        else if (_transfers[transferHash] != 0) {
            revert Bridge_TransferAlreadyProcessed(transferHash);
        }
        // check signature if not from account
        else if (transfer_.from != _msgSender()) {
            _verifySignature(transfer_.from, transferHash, signature);
        }
    }

    /// @inheritdoc IBridge
    function quoteTransfer(uint16 targetChainBid) external view override returns (uint256) {
        return _quoteTransmitMessage(targetChainBid);
    }

    /**
     *
     */
    /* Foreign-chain transfer handling  */

    /// @inheritdoc WormholeMessenger
    function _handleMessage(bytes memory payload) internal override {
        MessageTransfer memory message = LibMessageTransfer.decode(payload);

        _doCrosschainTransfer(message);

        emit TransferedCrosschain(keccak256(payload), message);
    }

    /// @dev Handle a crosschain transfer message.
    /// @param mTransfer The transfer message.
    function _doCrosschainTransfer(MessageTransfer memory mTransfer) private {
        address contractAddress = LibAsset.computeReplicaAddress(mTransfer.assetHash);

        IReplica(contractAddress).crosschainMint(mTransfer.assetType, mTransfer.to, mTransfer.params);
    }

    /**
     *
     */
    /* Assets management  */

    /// @dev Transfer logic for asset management.
    /// @param transfer_ The transfer data.
    function _doTransfer(Transfer calldata transfer_) private {
        address contractAddress = LibAsset.computeReplicaAddress(transfer_.assetHash);

        IReplica(contractAddress).crosschainBurn(transfer_.assetType, transfer_.from, transfer_.params);
    }

    /**
     *
     */
    /* Messanging management */

    /// @dev Forward the transfer to the target chain.
    /// @param transfer_ The transfer data.
    function _doForwardCrosschainTransfer(Transfer calldata transfer_) private returns (uint64 sequence) {
        MessageTransfer memory message = MessageTransfer({
            assetType: transfer_.assetType,
            assetHash: transfer_.assetHash,
            to: transfer_.to,
            params: transfer_.params,
            nonce: transfer_.nonce
        });

        // forward the transfer to the relayer
        sequence = _sendMessage(transfer_.chainBid, message.encode(), _msgSender());
    }

    // @inheritdoc IBridge
    function getTransferSequence(bytes32 transferHash) external view override returns (uint64) {
        return _transfers[transferHash];
    }

    /**
     *
     */
    /* EIP721 Utils   */

    /// @dev Compute the hash of a data structure following EIP-712 spec.
    /// @param dataHash_ the structHash(message) to hash
    function hash(bytes32 dataHash_) external view returns (bytes32) {
        return _hash(dataHash_);
    }

    /// @dev Compute the hash of a data structure following EIP-712 spec.
    /// @param dataHash_ the structHash(message) to hash
    function _hash(bytes32 dataHash_) private view returns (bytes32) {
        return _hashTypedDataV4(dataHash_);
    }

    /// @dev validate a signature originator. Handle EIP1271 and EOA signatures using SignatureChecker library.
    /// @param signer the expected signer address
    /// @param digest the digest hash supposed to be signed
    /// @param signature the signature to verify
    function _verifySignature(address signer, bytes32 digest, bytes calldata signature) private view {
        bool isValid = signer.isValidSignatureNow(digest, signature);
        if (!isValid) {
            revert Bridge_InvalidSignature(signer, digest, signature);
        }
    }
}
