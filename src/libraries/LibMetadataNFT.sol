// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {IERC721Metadata} from "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import {MetadataNFT} from "../types/MetadataNFT.sol";

/// @custom:security-contact contact@stack3.dev
library LibMetadataNFT {
    function encode(MetadataNFT memory metadata) internal pure returns (bytes memory) {
        return abi.encode(metadata.name, metadata.symbol);
    }

    function decode(bytes memory data) internal pure returns (MetadataNFT memory) {
        (string memory name, string memory symbol) = abi.decode(data, (string, string));
        return MetadataNFT(name, symbol);
    }

    function tryRead(address token) internal view returns (MetadataNFT memory metadata) {
        try IERC721Metadata(token).name() returns (string memory name) {
            metadata.name = name;
        } catch {}

        try IERC721Metadata(token).symbol() returns (string memory symbol) {
            metadata.symbol = symbol;
        } catch {}
    }
}
