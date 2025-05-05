// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {LibBytes32} from "../../libraries/LibBytes32.sol";
import {Asset} from "../Replica.sol";
import {IXFT, IERC7802} from "../interfaces/IXFT.sol";
import {RFTCore} from "../FT/RFTCore.sol";

/// @title XFTAdapter
/// @author stack3
/// @notice The XFT adapter contract.
/// @dev The XFTAdapter contract is used to connect an existing XERC20 token to the bridge.
/// @dev the XFT token must allow the bridge adapter contract to call crosschainMint and crosschainBurn.
/// @custom:security-contact contact@stack3.dev
contract XFTAdapter is RFTCore {
    using LibBytes32 for bytes32;

    IXFT private immutable _innerToken;

    constructor(Asset memory asset, address bridgeAddress) RFTCore(asset, bridgeAddress) {
        _innerToken = IXFT(asset.address_);
    }

    /// @inheritdoc IERC7802
    function crosschainMint(address _to, uint256 _amount) external override onlyBridge {
        _innerToken.crosschainMint(_to, _amount);

        emit CrosschainMint(_to, _amount, msg.sender);
    }

    /// @inheritdoc IERC7802
    function crosschainBurn(address _from, uint256 _amount) external override onlyBridge {
        _innerToken.crosschainBurn(_from, _amount);

        emit CrosschainBurn(_from, _amount, msg.sender);
    }

    /// @inheritdoc IXFT
    function decimals() external view override returns (uint8) {
        return _innerToken.decimals();
    }
}
