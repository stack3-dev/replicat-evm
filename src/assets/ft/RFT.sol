// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {ERC20, IERC20, IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {ERC20Permit} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import {RFTCore, IXFT, IReplica, IERC7802} from "./RFTCore.sol";
import {LibBytes32} from "../../libraries/LibBytes32.sol";
import {Asset} from "../../types/Asset.sol";
import {MetadataFT, LibMetadataFT} from "../../types/MetadataFT.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

/// @title RFT
/// @author stack3
/// @notice The fungible token replica contract.
/// @dev This contract is an ERC20 token that represents a fungible token.
/// @custom:security-contact contact@stack3.dev
contract RFT is RFTCore, ERC20, ERC20Permit {
    using LibBytes32 for bytes32;

    string private constant NAME_SUFFIX = " (replicaT)";

    constructor(Asset memory asset, MetadataFT memory metadata, address bridgeAddress)
        RFTCore(asset, bridgeAddress)
        ERC20(metadata.name, metadata.symbol)
        ERC20Permit(asset.hash().toHexString())
    {}

    /// @inheritdoc ERC20
    function name() public view override returns (string memory) {
        return string.concat(_metadataFT().name, NAME_SUFFIX);
    }

    /// @inheritdoc ERC20
    function symbol() public view override returns (string memory) {
        return _metadataFT().symbol;
    }

    /// @inheritdoc ERC20
    function decimals() public view override(ERC20, IXFT) returns (uint8) {
        return _metadataFT().decimals;
    }

    /// @notice private function retreive the token metadata
    function _metadataFT() private view returns (MetadataFT memory) {
        return LibMetadataFT.decode(_asset().metadata);
    }

    /// @inheritdoc IERC7802
    function crosschainBurn(address from, uint256 amount) external override onlyBridge {
        _burn(from, amount);

        emit CrosschainBurn(from, amount, msg.sender);
    }

    /// @inheritdoc IERC7802
    function crosschainMint(address to, uint256 amount) external override onlyBridge {
        _mint(to, amount);

        emit CrosschainMint(to, amount, msg.sender);
    }

    /// @inheritdoc RFTCore
    function supportsInterface(bytes4 _interfaceId) public pure override returns (bool) {
        return _interfaceId == type(IERC20).interfaceId || supportsInterface(_interfaceId);
    }
}
