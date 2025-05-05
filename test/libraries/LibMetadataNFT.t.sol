// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {Test, console} from "forge-std/Test.sol";
import {MetadataNFT, LibMetadataNFT} from "../../src/types/MetadataNFT.sol";
import {ERC721Mock} from "../utils/ERC721Mock.sol";

contract LibMetadataNFTTest is Test {
    function setUp() public {}

    function test_encoding_t() public pure {
        bytes memory source = abi.encode("Test", "TST");
        MetadataNFT memory decoded = LibMetadataNFT.decode(source);
        bytes memory encoded = LibMetadataNFT.encode(decoded);

        assertEq(source, encoded);
        assertEq(decoded.name, "Test");
        assertEq(decoded.symbol, "TST");
    }

    function test_try_read() public {
        ERC721Mock erc721 = new ERC721Mock("Test", "TST");

        MetadataNFT memory metadata = LibMetadataNFT.tryRead(address(erc721));

        assertEq(metadata.name, "Test");
        assertEq(metadata.symbol, "TST");
    }
}
