// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {Test, console} from "forge-std/Test.sol";
import {MetadataFT, LibMetadataFT} from "../../src/types/MetadataFT.sol";
import {ERC20Mock} from "../utils/ERC20Mock.sol";

contract LibMetadataFTTest is Test {
    function setUp() public {}

    function test_encoding_metadata_erc20() public pure {
        bytes memory source = abi.encode("Test", "TST", uint8(18));
        MetadataFT memory decoded = LibMetadataFT.decode(source);
        bytes memory encoded = LibMetadataFT.encode(decoded);

        assertEq(source, encoded);
        assertEq(decoded.name, "Test");
        assertEq(decoded.symbol, "TST");
        assertEq(decoded.decimals, 18);
    }

    function test_try_read() public {
        ERC20Mock erc20 = new ERC20Mock("Test", "TST");

        MetadataFT memory metadata = LibMetadataFT.tryRead(address(erc20));

        assertEq(metadata.name, "Test");
        assertEq(metadata.symbol, "TST");
        assertEq(metadata.decimals, 18);
    }

    function test_encoding_metadata_link() public pure {
        bytes memory source = abi.encode("ChainLink Token", "LINK", uint8(18));
        MetadataFT memory decoded = LibMetadataFT.decode(source);
        bytes memory encoded = LibMetadataFT.encode(decoded);

        assertEq(decoded.name, "ChainLink Token");
        assertEq(decoded.symbol, "LINK");
        assertEq(decoded.decimals, 18);
        assertEq(source, encoded);
    }
}
