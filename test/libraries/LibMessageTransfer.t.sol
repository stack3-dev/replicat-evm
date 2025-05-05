// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {Test, console} from "forge-std/Test.sol";
import {MessageTransfer, LibMessageTransfer} from "../../src/types/MessageTransfer.sol";
import {TransferParamsFT} from "../../src/types/TransferParamsFT.sol";

contract LibMessageTransferTest is Test {
    function setUp() public {}

    function test_encoding() public pure {
        bytes memory source =
            abi.encode(uint8(1), keccak256("TestAssetHash"), address(0xa11ce), TransferParamsFT(1337, 18).encode(), 1);
        MessageTransfer memory decoded = LibMessageTransfer.decode(source);
        bytes memory encoded = LibMessageTransfer.encode(decoded);

        assertEq(source, encoded);
        assertEq(uint8(decoded.assetType), uint8(1));
        assertEq(decoded.assetHash, keccak256("TestAssetHash"));
        assertEq(decoded.to, address(0xa11ce));
        assertEq(decoded.params, TransferParamsFT(1337, 18).encode());
        assertEq(decoded.nonce, 1);
    }

    function test_decoding() public pure {
        bytes memory source =
            abi.encode(uint8(1), keccak256("TestAssetHash"), address(0xa11ce), TransferParamsFT(1337, 18).encode(), 1);
        MessageTransfer memory decoded = LibMessageTransfer.decode(source);

        assertEq(uint8(decoded.assetType), uint8(1));
        assertEq(decoded.assetHash, keccak256("TestAssetHash"));
        assertEq(decoded.to, address(0xa11ce));
        assertEq(decoded.params, TransferParamsFT(1337, 18).encode());
        assertEq(decoded.nonce, 1);
    }
}
