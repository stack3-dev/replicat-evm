// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {Test, console} from "forge-std/Test.sol";
import {BridgeBaseTest, WormholeRelayerMock} from "./BridgeBase.t.sol";

import {Bridge} from "../../src/bridge/Bridge.sol";
import {Asset} from "../../src/types/Asset.sol";
import {RFT} from "../../src/assets/ft/RFT.sol";
import {ETHEREUM_BID, FOUNDRY_BID} from "../../src/utils/BridgeChains.sol";
import {AssetType} from "../../src/types/AssetType.sol";
import {MetadataFT} from "../../src/types/MetadataFT.sol";
import {Transfer} from "../../src/types/Transfer.sol";
import {TransferParamsFT} from "../../src/types/TransferParamsFT.sol";
import {MessageTransfer} from "../../src/types/MessageTransfer.sol";

bytes4 constant MOCK_BRIDGE_CLASS = bytes4(keccak256("MOCK"));

contract BridgeTransfer_RFTTest is BridgeBaseTest {
    RFT public _rerc20;
    Asset public _asset;

    function _setUp() internal override {
        // define the bridged asset
        _asset = Asset({
            type_: AssetType.FT,
            chainBid: ETHEREUM_BID,
            address_: address(0x1337),
            metadata: MetadataFT({name: "ERC20Mock", symbol: "MCK", decimals: 18}).encode()
        });

        // Create the replica erc20
        address rerc20Address = _bridge.createReplica(_asset, "");
        _rerc20 = RFT(rerc20Address);
        _rerc20.approve(address(_bridge), UINT256_MAX);
    }

    function test_should_be_able_to_transfer_in_rerc20() public {
        // mint some RFT by triggering a crosschain transfer
        _mockReceive(
            MessageTransfer({
                assetType: AssetType.FT,
                assetHash: _asset.hash(),
                to: address(this),
                params: TransferParamsFT(100, 18).encode(),
                nonce: 1
            })
        );

        // verify the crosschain mint
        assertEq(100, _rerc20.balanceOf(address(this)));
    }

    function test_should_be_able_to_transfer_out_rerc20() public {
        // mint some RFT
        test_should_be_able_to_transfer_in_rerc20();

        // define the transfer
        Transfer memory transfer = Transfer({
            assetType: AssetType.FT,
            assetHash: _asset.hash(),
            from: address(this),
            to: address(0xa11ce),
            chainBid: ETHEREUM_BID,
            params: TransferParamsFT(100, 18).encode(),
            nonce: 1
        });

        // execute the transfer
        _bridge.transfer(transfer, new bytes(0));

        // assert the transfer
        assertEq(0, _rerc20.balanceOf(address(this)));
        assertEq(0, _rerc20.balanceOf(address(_bridge)));
        assertEq(0, _rerc20.balanceOf(address(0xa11ce)));

        // assert the message transfer
        WormholeRelayerMock.Message memory message = _wormholeRelayerMock.lastSent();
        assertEq(ETHEREUM_BID, message.targetChain);
        assertEq(address(_bridge), message.targetAddress);
        assertEq(
            message.payload,
            MessageTransfer({
                assetType: AssetType.FT,
                assetHash: _asset.hash(),
                to: address(0xa11ce),
                params: TransferParamsFT(100, 18).encode(),
                nonce: 1
            }).encode()
        );
    }

    function test_should_be_able_to_transfer_in_rerc20_with_custom_decimals() public {
        // mint some RFT by triggering a crosschain transfer
        _mockReceive(
            MessageTransfer({
                assetType: AssetType.FT,
                assetHash: _asset.hash(),
                to: address(this),
                params: TransferParamsFT(1, 16).encode(),
                nonce: 1
            })
        );

        // verify the crosschain mint
        assertEq(100, _rerc20.balanceOf(address(this)));
    }

    function test_should_be_able_to_transfer_out_rerc20_with_custom_decimals() public {
        // mint some RFT
        test_should_be_able_to_transfer_in_rerc20();

        // define the transfer
        Transfer memory transfer = Transfer({
            assetType: AssetType.FT,
            assetHash: _asset.hash(),
            from: address(this),
            to: address(0xa11ce),
            chainBid: ETHEREUM_BID,
            params: TransferParamsFT(10, 17).encode(),
            nonce: 1
        });

        // execute the transfer
        _bridge.transfer(transfer, new bytes(0));

        // assert the transfer
        assertEq(0, _rerc20.balanceOf(address(this)));
        assertEq(0, _rerc20.balanceOf(address(_bridge)));
        assertEq(0, _rerc20.balanceOf(address(0xa11ce)));

        // assert the message transfer
        WormholeRelayerMock.Message memory message = _wormholeRelayerMock.lastSent();

        assertEq(ETHEREUM_BID, message.targetChain);
        assertEq(address(_bridge), message.targetAddress);
        assertEq(
            message.payload,
            MessageTransfer({
                assetType: AssetType.FT,
                assetHash: _asset.hash(),
                to: address(0xa11ce),
                params: TransferParamsFT(10, 17).encode(),
                nonce: 1
            }).encode()
        );
    }
}
