// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {Test, console} from "forge-std/Test.sol";
import {LibAsset, Asset} from "../../src/libraries/LibAsset.sol";
import {AssetType} from "../../src/types/AssetType.sol";
import {MetadataFT} from "../../src/types/MetadataFT.sol";

contract LibAssetTest is Test {
    using LibAsset for Asset;

    function setUp() public {}

    function test_hash() public pure {
        Asset memory asset = Asset({
            type_: AssetType.FT,
            chainBid: 11155111,
            address_: address(0x779877A7B0D9E8603169DdbD7836e478b4624789),
            metadata: MetadataFT({name: "Test", symbol: "TST", decimals: 18}).encode()
        });

        bytes32 hash = asset.hash();

        assertEq(hash, 0xcfcb65f5fbc6108c224015b555702fcea4d720f19cafa95044547cff0902350b);
    }
}
