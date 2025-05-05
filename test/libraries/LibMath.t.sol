// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {Test, console} from "forge-std/Test.sol";
import {LibMath} from "../../src/libraries/LibMath.sol";

contract LibBpTest is Test {
    using LibMath for uint256;

    function setUp() public {}

    function test_should_compute_fee() public pure {
        assertEq(uint256(100_000).bp(15_00), 15_000);
        assertEq(uint256(100_000).bp(0), 0);
        assertEq(uint256(100_000).bp(100_00), 100_000);
        assertEq(uint256(100_000).bp(100_01), 100_010);
        assertEq(uint256(100_000).bp(100_99), 100_990);
        assertEq(uint256(100_000).bp(100_50), 100_500);
        assertEq(uint256(100).bp(100_50), 101);
        assertEq(uint256(100).bp(100_99), 101);
        assertEq(uint256(100).bp(100_00), 100);
        assertEq(uint256(100).bp(100_01), 101);
        assertEq(uint256(100).bp(0), 0);
    }

    function test_should_compute_inflate() public pure {
        assertEq(uint256(100_000).inflate(15_00), 115_000);
        assertEq(uint256(100_000).inflate(0), 100_000);
        assertEq(uint256(100_000).inflate(100_00), 200_000);
        assertEq(uint256(100_000).inflate(100_01), 200_010);
        assertEq(uint256(100_000).inflate(100_99), 200_990);
        assertEq(uint256(100_000).inflate(100_50), 200_500);
        assertEq(uint256(100).inflate(100_00), 200);
        assertEq(uint256(100).inflate(100_50), 201);
        assertEq(uint256(100).inflate(100_99), 201);
        assertEq(uint256(100).inflate(100_01), 201);
        assertEq(uint256(100).inflate(0), 100);
    }

    function test_should_compute_before_inflate() public pure {
        assertEq(uint256(115_000).beforeInflate(15_00), 100_000);
        assertEq(uint256(100_000).beforeInflate(0), 100_000);
        assertEq(uint256(200_000).beforeInflate(100_00), 100_000);
        assertEq(uint256(200_010).beforeInflate(100_01), 100_000);
        assertEq(uint256(200_990).beforeInflate(100_99), 100_000);
        assertEq(uint256(200_500).beforeInflate(100_50), 100_000);
        assertEq(uint256(200).beforeInflate(100_00), 100);
        assertEq(uint256(201).beforeInflate(100_50), 101);
        assertEq(uint256(201).beforeInflate(100_99), 101);
        assertEq(uint256(201).beforeInflate(100_01), 101);
        assertEq(uint256(100).beforeInflate(0), 100);
        assertEq(uint256(115).beforeInflate(15_00), 100);
    }

    function test_should_convert_decimals() public {
        (uint256 result, uint256 rest) = uint256(1).toDecimals(1, 1);
        assertEq(result, 1);
        assertEq(rest, 0);

        (result, rest) = uint256(1).toDecimals(0, 1);
        assertEq(result, 10);
        assertEq(rest, 0);

        (result, rest) = uint256(1).toDecimals(1, 0);
        assertEq(result, 0);
        assertEq(rest, 1);

        (result, rest) = uint256(1).toDecimals(6, 8);
        assertEq(result, 100);
        assertEq(rest, 0);

        (result, rest) = uint256(12345).toDecimals(8, 6);
        assertEq(result, 123);
        assertEq(rest, 45);

        (result, rest) = uint256(12345).toDecimals(6, 8);
        assertEq(result, 1234500);
        assertEq(rest, 0);
    }
}
