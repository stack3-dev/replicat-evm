// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {Test, console} from "forge-std/Test.sol";
import {RNFT, Asset} from "../../src/assets/nft/RNFT.sol";
import {AssetType} from "../../src/types/Asset.sol";
import {MetadataNFT} from "../../src/types/MetadataNFT.sol";
import {Replica} from "../../src/assets/Replica.sol";

contract RNFTTest is Test {
    RNFT private _RNFT;
    Asset private _asset = Asset({
        type_: AssetType.NFT,
        chainBid: 1,
        address_: address(1001),
        metadata: MetadataNFT({name: "Test", symbol: "TST"}).encode()
    });

    function setUp() public {
        _RNFT =
            new RNFT(_asset, MetadataNFT({name: "Test", symbol: "TST"}), address(this), "https://mockURI.com/token/");
    }

    function test_should_return_name() public view {
        assertEq(_RNFT.name(), "Test (replicaT)");
    }

    function test_should_return_symbol() public view {
        assertEq(_RNFT.symbol(), "TST");
    }

    function test_should_update_baseURI() public {
        _RNFT.setBaseURI("https://mockURI.com/token2/");
        _RNFT.crosschainMint(address(1), 1);

        assertEq(_RNFT.tokenURI(1), "https://mockURI.com/token2/1");
    }

    function test_should_return_asset_hash() public view {
        assertEq(_RNFT.assetHash(), _asset.hash());
    }

    function test_should_return_asset_type() public view {
        assertEq(uint8(_RNFT.asset().type_), uint8(_asset.type_));
    }

    function test_should_return_asset_chain_bid() public view {
        assertEq(_RNFT.asset().chainBid, _asset.chainBid);
    }

    function test_should_return_asset_address() public view {
        assertEq(_RNFT.asset().address_, _asset.address_);
    }

    function test_should_return_bridge_address() public view {
        assertEq(_RNFT.bridgeAddress(), address(this));
    }

    function test_should_handle_base_uri() public {
        // mint token '1'
        _RNFT.crosschainMint(address(1), 1);

        assertEq(_RNFT.tokenURI(1), "https://mockURI.com/token/1");
    }

    function test_should_allow_bridge_to_mint() public {
        // mint token '2'
        _RNFT.crosschainMint(address(1), 1);
    }

    function test_should_allow_bridge_to_burn() public {
        test_should_allow_bridge_to_mint();

        // burn token '2'
        _RNFT.crosschainBurn(address(1), 1);
    }

    function test_should_revert_mint_if_not_bridge() public {
        address signer = vm.addr(0xa11ce);

        vm.prank(signer);
        vm.expectRevert(abi.encodeWithSelector(Replica.Replica_UnauthorizedBridge.selector, signer));
        _RNFT.crosschainMint(address(1), 1);
    }

    function test_should_revert_burn_if_not_bridge() public {
        test_should_allow_bridge_to_mint();

        address signer = vm.addr(0xa11ce);

        vm.prank(signer);
        vm.expectRevert(abi.encodeWithSelector(Replica.Replica_UnauthorizedBridge.selector, signer));
        _RNFT.crosschainBurn(address(1), 1);
    }
}
