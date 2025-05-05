// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {Test, console} from "forge-std/Test.sol";
import {RFT, Asset} from "../../src/assets/ft/RFT.sol";
import {Replica} from "../../src/assets/Replica.sol";
import {AssetType} from "../../src/types/Asset.sol";
import {MetadataFT} from "../../src/types/MetadataFT.sol";
import {LibBytes32} from "../../src/libraries/LibBytes32.sol";

contract RFTTest is Test {
    RFT private _RFT;
    Asset private _asset = Asset({
        type_: AssetType.FT,
        chainBid: 1,
        address_: address(1001),
        metadata: MetadataFT({name: "Test", symbol: "TST", decimals: 18}).encode()
    });

    function setUp() public {
        _RFT = new RFT(_asset, MetadataFT({name: "Test", symbol: "TST", decimals: 18}), address(this));
    }

    function test_should_return_name() public view {
        assertEq(_RFT.name(), "Test (replicaT)");
    }

    function test_should_return_symbol() public view {
        assertEq(_RFT.symbol(), "TST");
    }

    function test_should_return_decimals() public view {
        assertEq(_RFT.decimals(), 18);
    }

    function test_should_return_asset_hash() public view {
        assertEq(_RFT.assetHash(), _asset.hash());
    }

    function test_should_return_asset_type() public view {
        assertEq(uint8(_RFT.asset().type_), uint8(_asset.type_));
    }

    function test_should_return_asset_chain_bid() public view {
        assertEq(_RFT.asset().chainBid, _asset.chainBid);
    }

    function test_should_return_asset_address() public view {
        assertEq(_RFT.asset().address_, _asset.address_);
    }

    function test_should_return_bridge_address() public view {
        assertEq(_RFT.bridgeAddress(), address(this));
    }

    function test_should_allow_bridge_to_mint() public {
        _RFT.crosschainMint(address(1), 1);
    }

    function test_should_allow_bridge_to_burn() public {
        test_should_allow_bridge_to_mint();

        _RFT.crosschainBurn(address(1), 1);
    }

    function test_should_revert_mint_if_not_bridge() public {
        address signer = vm.addr(0xa11ce);

        vm.prank(signer);
        vm.expectRevert(abi.encodeWithSelector(Replica.Replica_UnauthorizedBridge.selector, signer));
        _RFT.crosschainMint(address(1), 1);
    }

    function test_should_revert_burn_if_not_bridge() public {
        test_should_allow_bridge_to_mint();

        address signer = vm.addr(0xa11ce);

        vm.prank(signer);
        vm.expectRevert(abi.encodeWithSelector(Replica.Replica_UnauthorizedBridge.selector, signer));
        _RFT.crosschainBurn(address(1), 1);
    }
}
