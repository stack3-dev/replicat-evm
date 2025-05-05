// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {CREATE3} from "../vendors/CREATE3.sol";
import {CREATE_BRIDGE_SALT} from "../utils/CreateSalt.sol";
import {Bridge} from "./Bridge.sol";

/// @title Bridge Deployer
/// @author stack3
/// @notice The deployer contract
/// @dev This contract is used to deploy the bridge using CREATE3.
/// @custom:security-contact contact@stack3.dev
contract BridgeDeployer {
    address public immutable _initialOwner;

    /// @notice Constructor
    /// @param initialOwner The initial owner of the bridge
    constructor(address initialOwner) {
        _initialOwner = initialOwner;
    }

    /// @notice Deploys the bridge contract using CREATE3
    /// @dev This function deploys the bridge contract using CREATE3 and the provided salt
    /// @param wormholeChainId The wormhole chain ID
    /// @param wormholeRelayer The address of the wormhole relayer contract
    /// @return The address of the deployed bridge contract
    function deploy(uint16 wormholeChainId, address wormholeRelayer) external returns (address) {
        return CREATE3.deployDeterministic(
            abi.encodePacked(type(Bridge).creationCode, abi.encode(_initialOwner, wormholeChainId, wormholeRelayer)),
            CREATE_BRIDGE_SALT
        );
    }

    /// @notice Returns the address of the deployed bridge contract
    /// @dev This function returns the address of the deployed bridge contract using CREATE3 and the provided salt
    /// @return The address of the deployed bridge contract
    function bridgeAddress() external view returns (address) {
        return CREATE3.predictDeterministicAddress(CREATE_BRIDGE_SALT);
    }
}
