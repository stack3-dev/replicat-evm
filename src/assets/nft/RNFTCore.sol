// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity 0.8.28;

import {IXNFT, IERC165} from "../interfaces/IXNFT.sol";
import {IReplica, Replica, Asset} from "../Replica.sol";

/// @title RNFTCore
/// @author stack3
/// @notice The Non-Fungible Token replica core contract
/// @dev Implement this contract to be compliant with the ReplicaT bridge.
/// @custom:security-contact contact@stack3.dev
abstract contract RNFTCore is IXNFT, Replica {
    modifier onlyBridge() {
        if (msg.sender != _bridgeAddress()) {
            revert Replica_UnauthorizedBridge(msg.sender);
        }
        _;
    }

    /// @notice Constructor
    /// @param asset the asset data
    /// @param bridgeAddress the local bridge address
    constructor(Asset memory asset, address bridgeAddress) Replica(asset, bridgeAddress) {}

    /// @inheritdoc IERC165
    function supportsInterface(bytes4 _interfaceId) public view virtual override returns (bool) {
        return _interfaceId == type(IXNFT).interfaceId || _interfaceId == type(IReplica).interfaceId
            || _interfaceId == type(IERC165).interfaceId;
    }
}
