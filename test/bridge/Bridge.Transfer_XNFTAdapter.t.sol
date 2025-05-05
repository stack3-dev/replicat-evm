// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {Test, console} from "forge-std/Test.sol";
import {BridgeBaseTest, WormholeRelayerMock} from "./BridgeBase.t.sol";

import {Bridge, IBridge} from "../../src/bridge/Bridge.sol";
import {ERC721Holder} from "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import {Asset} from "../../src/types/Asset.sol";
import {AssetType} from "../../src/types/AssetType.sol";
import {MetadataNFT} from "../../src/types/MetadataNFT.sol";
import {TransferParamsNFT} from "../../src/types/TransferParamsNFT.sol";
import {XERC721Mock} from "../utils/XERC721Mock.sol";
import {Transfer} from "../../src/types/Transfer.sol";
import {MessageTransfer} from "../../src/types/MessageTransfer.sol";
import {FOUNDRY_BID, ETHEREUM_BID} from "../../src/utils/BridgeChains.sol";
import {ECDSA} from "openzeppelin-contracts/contracts/utils/cryptography/ECDSA.sol";
import {LibReplica} from "../../src/libraries/LibReplica.sol";
import {XNFTAdapter} from "../../src/assets/nft/XNFTAdapter.sol";

bytes4 constant MOCK_BRIDGE_CLASS = bytes4(keccak256("MOCK"));
bytes32 constant PERMIT_TYPEHASH =
    keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");

contract BridgeTransfeXNFTAdapterTest is BridgeBaseTest, ERC721Holder {
    XERC721Mock public _xerc721;
    XNFTAdapter public _adapter;
    Asset public _asset;

    function _setUp() internal override {
        console.log("BridgeTransferXNFTAdapterTest::setUp");

        // instantiate an ERC20
        _xerc721 = new XERC721Mock("XERC721Mock", "MCK", address(_bridge));

        // define the asset
        _asset = Asset({
            type_: AssetType.XNFT,
            chainBid: 0,
            address_: address(_xerc721),
            metadata: MetadataNFT("XERC721Mock", "MCK").encode()
        });

        // Create the adapter erc20
        _adapter = XNFTAdapter(_bridge.createReplicaAdapter(_asset));
    }

    function test_should_be_able_to_transfer_out_xerc721() public {
        // mint some XERC20
        _xerc721.mint(address(this), 1337);

        // define the transfer
        Transfer memory transfer = Transfer({
            assetType: AssetType.XNFT,
            assetHash: _asset.hash(),
            from: address(this),
            to: address(0xa11ce),
            chainBid: ETHEREUM_BID,
            params: TransferParamsNFT(1337).encode(),
            nonce: 1
        });

        // execute the transfer
        _bridge.transfer(transfer, "");

        // assert the transfer
        assertEq(0, _xerc721.balanceOf(address(this)));
        assertEq(0, _xerc721.balanceOf(address(_adapter)));
        assertEq(0, _xerc721.balanceOf(address(_bridge)));
        assertEq(0, _xerc721.balanceOf(address(0xa11ce)));

        // assert the message transfer
        WormholeRelayerMock.Message memory message = _wormholeRelayerMock.lastSent();
        assertEq(ETHEREUM_BID, message.targetChain);
        assertEq(address(_bridge), message.targetAddress);
        assertEq(
            message.payload,
            MessageTransfer({
                assetType: AssetType.XNFT,
                assetHash: _asset.hash(),
                to: address(0xa11ce),
                params: TransferParamsNFT(1337).encode(),
                nonce: 1
            }).encode()
        );
    }

    function test_should_not_be_able_to_transfer_out_xerc721_with_invalid_params() public {
        // define the transfer
        Transfer memory transfer = Transfer({
            assetType: AssetType.XNFT,
            assetHash: _asset.hash(),
            from: address(this),
            to: address(this),
            chainBid: ETHEREUM_BID,
            params: "", // invalid params
            nonce: 1
        });

        // execute the transfer
        vm.expectRevert();

        _bridge.transfer(transfer, "");
    }

    function test_should_be_able_to_transfer_in_xerc721() public {
        // trigger the asset release
        _mockReceive(
            MessageTransfer({
                assetType: AssetType.XNFT,
                assetHash: _asset.hash(),
                to: address(0xa11ce),
                params: TransferParamsNFT(1337).encode(),
                nonce: 1
            })
        );

        // verify the release
        assertEq(0, _xerc721.balanceOf(address(this)));
        assertEq(0, _xerc721.balanceOf(address(_adapter)));
        assertEq(1, _xerc721.balanceOf(address(0xa11ce)));
        assertEq(address(0xa11ce), _xerc721.ownerOf(1337));
    }
}
