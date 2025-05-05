// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {IBridge} from "../bridge/interfaces/IBridge.sol";
import {IReplicaFactory} from "./interfaces/IReplicaFactory.sol";
import {LibAssetCreateReplica} from "../libraries/LibAssetCreateReplica.sol";
import {LibAssetCreateReplicaAdapter} from "../libraries/LibAssetCreateReplicaAdapter.sol";
import {Asset} from "../types/Asset.sol";

/// @title ReplicaFactory
/// @notice Factory contract to create new assets
/// @dev This contract is responsible for creating new assets and registering them in the asset registry
/// @custom:security-contact contact@stack3.dev
abstract contract ReplicaFactory is IReplicaFactory {
    using Address for address payable;
    using LibAssetCreateReplica for Asset;
    using LibAssetCreateReplicaAdapter for Asset;

    IBridge private _bridge;
    uint256 private _fee;

    event ReplicaFactory_FeeUpdated(uint256 fee);
    event ReplicaFactory_FeesWithdrawn(address payee, uint256 amount);

    error ReplicaFactory_InsufficientFee();

    constructor(IBridge bridge) {
        _bridge = bridge;
    }

    function createReplica(Asset calldata asset, bytes calldata extraArgs)
        external
        payable
        override
        returns (address replicaAddress)
    {
        if (msg.value < _fee) {
            revert ReplicaFactory_InsufficientFee();
        }

        replicaAddress = asset.createReplica(_bridge, extraArgs);

        emit ReplicaCreated(asset.hash(), replicaAddress, msg.sender, asset);
    }

    function createReplicaAdapter(Asset calldata asset)
        external
        payable
        override
        returns (address replicaAdapterAddress)
    {
        if (msg.value < _fee) {
            revert ReplicaFactory_InsufficientFee();
        }

        replicaAdapterAddress = asset.createReplicaAdapter(_bridge);

        emit ReplicaAdapterCreated(asset.hash(), replicaAdapterAddress, msg.sender, asset);
    }

    function computeReplicaAddress(Asset calldata asset) external view returns (address) {
        return asset.computeReplicaAddress();
    }

    function _setFactoryFee(uint256 fee) internal {
        _fee = fee;

        emit ReplicaFactory_FeeUpdated(fee);
    }

    function getFactoryFee() external view returns (uint256) {
        return _fee;
    }

    function _withdrawFactoryFees(address payable payee) internal {
        uint256 balance = address(this).balance;
        payee.sendValue(balance);
        emit ReplicaFactory_FeesWithdrawn(payee, balance);
    }
}
