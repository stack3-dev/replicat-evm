// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {IXFT, IERC7802, IERC165} from "../interfaces/IXFT.sol";
import {IReplica, Replica, Asset} from "..//Replica.sol";
import {PredeployAddresses} from "@interop-lib/libraries/PredeployAddresses.sol";

/// @title RFTCore
/// @author stack3
/// @notice The Fungible Token replica core contract.
/// @dev Implement this contract to be compliant with the ReplicaT bridge.
/// @custom:security-contact contact@stack3.dev
abstract contract RFTCore is IXFT, Replica {
    modifier onlyBridge() {
        if (msg.sender != _bridgeAddress() && msg.sender != PredeployAddresses.SUPERCHAIN_TOKEN_BRIDGE) {
            revert Replica_UnauthorizedBridge(msg.sender);
        }
        _;
    }

    /// @notice Constructor
    /// @param asset the asset data
    /// @param bridgeAddress the local bridge address
    constructor(Asset memory asset, address bridgeAddress) Replica(asset, bridgeAddress) {}

    /// @inheritdoc IERC165
    function supportsInterface(bytes4 _interfaceId) public pure virtual override returns (bool) {
        return _interfaceId == type(IERC7802).interfaceId || _interfaceId == type(IXFT).interfaceId
            || _interfaceId == type(IReplica).interfaceId || _interfaceId == type(IERC165).interfaceId;
    }
}
