// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {Test, console} from "forge-std/Test.sol";
import {TransferParamsNFT, LibTransferParamsNFT} from "../../src/types/TransferParamsNFT.sol";
import {ERC721Mock} from "../utils/ERC721Mock.sol";

contract LibTransferParamsNFTTest is Test {
    function setUp() public {}

    function test_encoding() public pure {
        bytes memory source = abi.encode(uint256(1337));
        TransferParamsNFT memory decoded = LibTransferParamsNFT.decode(source);
        bytes memory encoded = LibTransferParamsNFT.encode(decoded);

        assertEq(source, encoded);
        assertEq(decoded.tokenId, 1337);
    }
}
