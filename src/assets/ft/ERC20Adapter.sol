// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {SafeERC20, IERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {RFTCore, IERC7802, Asset} from "./RFTCore.sol";
import {LibBytes32} from "../../libraries/LibBytes32.sol";
import {MetadataFT, LibMetadataFT} from "../../types/MetadataFT.sol";

/// @title ERC20Adapter
/// @author stack3
/// @notice The ERC20 replica adapter contract
/// @custom:security-contact contact@stack3.dev
contract ERC20Adapter is RFTCore {
    using SafeERC20 for IERC20;
    using LibBytes32 for bytes32;

    IERC20 internal immutable _innerToken;
    uint8 internal immutable _innerDecimals;

    constructor(Asset memory asset, address bridgeAddress) RFTCore(asset, bridgeAddress) {
        _innerToken = IERC20(asset.address_);
        MetadataFT memory innerMetadata = LibMetadataFT.decode(asset.metadata);
        _innerDecimals = innerMetadata.decimals;
    }

    /// @inheritdoc IERC7802
    function crosschainBurn(address from, uint256 amount) external override onlyBridge {
        _innerToken.safeTransferFrom(from, address(this), amount);

        emit CrosschainBurn(from, amount, msg.sender);
    }

    /// @inheritdoc IERC7802
    function crosschainMint(address to, uint256 amount) external override onlyBridge {
        _innerToken.safeTransfer(to, amount);

        emit CrosschainMint(to, amount, msg.sender);
    }

    function decimals() external view override returns (uint8) {
        return _innerDecimals;
    }
}
