// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {Test, console} from "forge-std/Test.sol";
import {BridgeBaseTest, WormholeRelayerMock} from "./BridgeBase.t.sol";
import {Bridge} from "../../src/bridge/Bridge.sol";
import {Asset} from "../../src/types/Asset.sol";
import {AssetType} from "../../src/types/AssetType.sol";
import {MetadataNFT} from "../../src/types/MetadataNFT.sol";
import {TransferParamsNFT} from "../../src/types/TransferParamsNFT.sol";
import {ERC721Mock} from "../utils/ERC721Mock.sol";
import {Transfer} from "../../src/types/Transfer.sol";
import {FOUNDRY_BID, ETHEREUM_BID} from "../../src/utils/BridgeChains.sol";
import {ERC721Holder} from "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import {ERC721Adapter} from "../../src/assets/nft/ERC721Adapter.sol";
import {MessageTransfer} from "../../src/types/MessageTransfer.sol";

bytes4 constant MOCK_BRIDGE_CLASS = bytes4(keccak256("MOCK"));

contract BridgeTransfeERC721AdapterTest is BridgeBaseTest, ERC721Holder {
    ERC721Mock public _erc721;
    Asset public _asset;
    ERC721Adapter public _adapter;

    function _setUp() internal override {
        // instantiate the ERC721 mock
        _erc721 = new ERC721Mock("ERC721Mock", "MCK");

        // create adapter
        _asset = Asset({
            type_: AssetType.NFT,
            chainBid: FOUNDRY_BID,
            address_: address(_erc721),
            metadata: MetadataNFT({name: "ERC721Mock", symbol: "MCK"}).encode()
        });
        _adapter = ERC721Adapter(_bridge.createReplicaAdapter(_asset));

        // approve the adapter
        _erc721.setApprovalForAll(address(_adapter), true);
    }

    function test_should_be_able_to_transfer_out_erc721() public {
        // mint some ERC721
        _erc721.mint(address(this), 1);

        // define the transfer
        Transfer memory transfer = Transfer({
            assetType: AssetType.NFT,
            assetHash: _asset.hash(),
            from: address(this),
            to: address(0xa11ce),
            chainBid: ETHEREUM_BID,
            params: TransferParamsNFT(1).encode(),
            nonce: 1
        });

        // execute the transfer
        _bridge.transfer(transfer, "");

        // assert the transfer
        assertEq(0, _erc721.balanceOf(address(this)));
        assertEq(1, _erc721.balanceOf(address(_adapter)));
        assertEq(0, _erc721.balanceOf(address(_bridge)));
        assertEq(0, _erc721.balanceOf(address(0xa11ce)));

        // assert the message transfer
        WormholeRelayerMock.Message memory message = _wormholeRelayerMock.lastSent();
        assertEq(ETHEREUM_BID, message.targetChain);
        assertEq(address(_bridge), message.targetAddress);
        assertEq(
            message.payload,
            MessageTransfer({
                assetType: AssetType.NFT,
                assetHash: _asset.hash(),
                to: address(0xa11ce),
                params: TransferParamsNFT(1).encode(),
                nonce: 1
            }).encode()
        );
    }

    function test_should_not_be_able_to_transfer_out_erc721_with_invalid_params() public {
        // define the transfer
        Transfer memory transfer = Transfer({
            assetType: AssetType.NFT,
            assetHash: _asset.hash(),
            from: address(this),
            to: address(0xa11ce),
            chainBid: ETHEREUM_BID,
            params: TransferParamsNFT(0).encode(), // invalid token id
            nonce: 1
        });

        // execute the transfer
        vm.expectRevert();
        _bridge.transfer(transfer, "");
    }

    function test_should_be_able_to_transfer_in_erc721() public {
        // lock some ERC20 in treasury
        test_should_be_able_to_transfer_out_erc721();

        // trigger the asset release
        _mockReceive(
            MessageTransfer({
                assetType: AssetType.NFT,
                assetHash: _asset.hash(),
                to: address(0xa11ce),
                params: TransferParamsNFT(1).encode(),
                nonce: 1
            })
        );

        // verify the release
        assertEq(0, _erc721.balanceOf(address(this)));
        assertEq(0, _erc721.balanceOf(address(_adapter)));
        assertEq(0, _erc721.balanceOf(address(_bridge)));
        assertEq(1, _erc721.balanceOf(address(0xa11ce)));
    }
}
