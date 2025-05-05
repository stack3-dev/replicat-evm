// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {Test, console} from "forge-std/Test.sol";
import {TransferParamsFT, LibTransferParamsFT} from "../../src/types/TransferParamsFT.sol";
import {ERC721Mock} from "../utils/ERC721Mock.sol";

contract LibTransferParamsFTTest is Test {
    function setUp() public {}

    function test_encoding_transfer_params_erc20() public pure {
        bytes memory source = abi.encode(uint256(1337), uint8(18));
        TransferParamsFT memory decoded = LibTransferParamsFT.decode(source);
        bytes memory encoded = LibTransferParamsFT.encode(decoded);

        assertEq(source, encoded);
        assertEq(decoded.amount, 1337);
        assertEq(decoded.decimals, 18);
    }
}
