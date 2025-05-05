// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {Test, console} from "forge-std/Test.sol";
import {BridgeBaseTest, WormholeRelayerMock} from "./BridgeBase.t.sol";

import {Bridge} from "../../src/bridge/Bridge.sol";
import {Asset} from "../../src/types/Asset.sol";
import {RNFT} from "../../src/assets/nft/RNFT.sol";
import {ETHEREUM_BID, FOUNDRY_BID} from "../../src/utils/BridgeChains.sol";
import {AssetType} from "../../src/types/AssetType.sol";
import {MetadataNFT} from "../../src/types/MetadataNFT.sol";
import {Transfer} from "../../src/types/Transfer.sol";
import {TransferParamsNFT} from "../../src/types/TransferParamsNFT.sol";
import {MessageTransfer} from "../../src/types/MessageTransfer.sol";
import {ERC721Holder} from "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";

bytes4 constant MOCK_BRIDGE_CLASS = bytes4(keccak256("MOCK"));

contract BridgeTransfer_RNFTTest is BridgeBaseTest, ERC721Holder {
    RNFT public _rerc721;
    Asset public _asset;

    function _setUp() internal override {
        //  define the asset
        _asset = Asset({
            type_: AssetType.NFT,
            chainBid: ETHEREUM_BID,
            address_: address(0x1337),
            metadata: MetadataNFT({name: "ERC721Mock", symbol: "MCK"}).encode()
        });
        // Create the replica erc20
        address rerc721Address = _bridge.createReplica(_asset, abi.encode("uri/"));
        _rerc721 = RNFT(rerc721Address);
    }

    function test_should_be_able_to_transfer_in_rerc721() public {
        // mint some RFT by triggering a crosschain transfer
        _mockReceive(
            MessageTransfer({
                assetType: AssetType.NFT,
                assetHash: _asset.hash(),
                to: address(this),
                params: TransferParamsNFT(1337).encode(),
                nonce: 1
            })
        );

        // verify the crosschain mint
        assertEq(1, _rerc721.balanceOf(address(this)));
        assertEq(0, _rerc721.balanceOf(address(_bridge)));
        assertEq(address(this), _rerc721.ownerOf(1337));
    }

    function test_should_be_able_to_transfer_out_rerc721() public {
        // mint some RNFT
        test_should_be_able_to_transfer_in_rerc721();

        // define the transfer
        Transfer memory transfer = Transfer({
            assetType: AssetType.NFT,
            assetHash: _asset.hash(),
            from: address(this),
            to: address(0xa11ce),
            chainBid: ETHEREUM_BID,
            params: TransferParamsNFT(1337).encode(),
            nonce: 1
        });

        // execute the transfer
        _rerc721.approve(address(_bridge), 1337);
        _bridge.transfer(transfer, "");

        // assert the transfer
        assertEq(0, _rerc721.balanceOf(address(this)));
        assertEq(0, _rerc721.balanceOf(address(_bridge)));
        assertEq(0, _rerc721.balanceOf(address(0xa11ce)));

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
                params: TransferParamsNFT(1337).encode(),
                nonce: 1
            }).encode()
        );
    }
}
