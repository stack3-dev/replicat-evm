// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {IERC20, IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {MetadataFT} from "../types/MetadataFT.sol";

/// @custom:security-contact contact@stack3.dev
library LibMetadataFT {
    function encode(MetadataFT memory metadata) internal pure returns (bytes memory) {
        return abi.encode(metadata.name, metadata.symbol, metadata.decimals);
    }

    function decode(bytes memory data) internal pure returns (MetadataFT memory) {
        (string memory name, string memory symbol, uint8 decimals) = abi.decode(data, (string, string, uint8));

        return MetadataFT(name, symbol, decimals);
    }

    function tryRead(address token) internal view returns (MetadataFT memory metadata) {
        try IERC20Metadata(token).name() returns (string memory name) {
            metadata.name = name;
        } catch {}

        try IERC20Metadata(token).symbol() returns (string memory symbol) {
            metadata.symbol = symbol;
        } catch {}

        try IERC20Metadata(token).decimals() returns (uint8 decimals) {
            metadata.decimals = decimals;
        } catch {}
    }
}
