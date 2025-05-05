// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {Test, console} from "forge-std/Test.sol";
import {LibBytes32} from "../../src/libraries/LibBytes32.sol";

contract LibBytes32Test is Test {
    using LibBytes32 for bytes32;

    function setUp() public {}

    function test_toHexString() public pure {
        assertEq(
            bytes32(keccak256("LOVE")).toHexString(),
            "0x36A3D4F69A1BCC6F8A31E9FF9845D9E8C25F8BBB01860C49113C39DDD021A3FB"
        );
    }
}
