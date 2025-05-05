// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {IReplica} from "./interfaces/IReplica.sol";
import {Asset} from "../types/Asset.sol";

/// @title Replica
/// @notice An abstract contract for an replicated asset.
/// @dev The contract is abstract and should be inherited by a concrete implementation.
/// @dev The implementation contract must provide a mint and burn functions protected by the access control.
/// @custom:security-contact contact@stack3.dev
abstract contract Replica is IReplica {
    address private immutable _bridgeAddress_;

    /// @notice The replicated asset hash
    bytes32 private immutable _assetHash;

    /// @notice The replicated asset datas
    Asset private _asset_;

    error Replica_UnauthorizedBridge(address sender);

    /// @notice Construct a new Asset
    constructor(Asset memory asset_, address bridgeAddress_) {
        _asset_ = asset_;
        _assetHash = asset_.hash();
        _bridgeAddress_ = bridgeAddress_;
    }

    /// @inheritdoc IReplica
    function assetHash() external view override returns (bytes32) {
        return _assetHash;
    }

    /// @inheritdoc IReplica
    function asset() external view returns (Asset memory) {
        return _asset();
    }

    function _asset() internal view returns (Asset memory) {
        return _asset_;
    }

    /// @inheritdoc IReplica
    function bridgeAddress() external view returns (address) {
        return _bridgeAddress();
    }

    /// @notice internal function to get the bridge address
    function _bridgeAddress() internal view returns (address) {
        return _bridgeAddress_;
    }
}
