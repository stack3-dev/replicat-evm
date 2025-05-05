// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {Test, console} from "forge-std/Test.sol";
import {BridgeBaseTest, WormholeRelayerMock} from "./BridgeBase.t.sol";

import {Bridge, IBridge} from "../../src/bridge/Bridge.sol";
import {Asset} from "../../src/types/Asset.sol";
import {AssetType} from "../../src/types/AssetType.sol";
import {MetadataFT} from "../../src/types/MetadataFT.sol";
import {TransferParamsFT} from "../../src/types/TransferParamsFT.sol";
import {XERC20Mock} from "../utils/XERC20Mock.sol";
import {Transfer} from "../../src/types/Transfer.sol";
import {MessageTransfer} from "../../src/types/MessageTransfer.sol";
import {FOUNDRY_BID, ETHEREUM_BID} from "../../src/utils/BridgeChains.sol";
import {ECDSA} from "openzeppelin-contracts/contracts/utils/cryptography/ECDSA.sol";
import {LibReplica} from "../../src/libraries/LibReplica.sol";
import {XFTAdapter} from "../../src/assets/ft/XFTAdapter.sol";

bytes4 constant MOCK_BRIDGE_CLASS = bytes4(keccak256("MOCK"));
bytes32 constant PERMIT_TYPEHASH =
    keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");

contract BridgeTransfeXFTAdapterTest is BridgeBaseTest {
    XERC20Mock public _xerc20;
    XFTAdapter public _adapter;
    Asset public _asset;

    function _setUp() internal override {
        // instantiate an ERC20
        _xerc20 = new XERC20Mock("ERC20Mock", "MCK", address(_bridge));

        // define the asset
        _asset = Asset({
            type_: AssetType.XFT,
            chainBid: 0,
            address_: address(_xerc20),
            metadata: MetadataFT("ERC20Mock", "MCK", 18).encode()
        });

        // Create the adapter erc20
        _adapter = XFTAdapter(_bridge.createReplicaAdapter(_asset));
    }

    function test_should_be_able_to_transfer_out_xerc20() public {
        // mint some XERC20
        _xerc20.mint(address(this), 100);

        // define the transfer
        Transfer memory transfer = Transfer({
            assetType: AssetType.XFT,
            assetHash: _asset.hash(),
            from: address(this),
            to: address(0xa11ce),
            chainBid: ETHEREUM_BID,
            params: TransferParamsFT(100, 18).encode(),
            nonce: 1
        });

        // execute the transfer
        _bridge.transfer(transfer, "");

        // assert the transfer
        assertEq(0, _xerc20.balanceOf(address(this)));
        assertEq(0, _xerc20.balanceOf(address(_adapter)));
        assertEq(0, _xerc20.balanceOf(address(_bridge)));
        assertEq(0, _xerc20.balanceOf(address(0xa11ce)));

        // assert the message transfer
        WormholeRelayerMock.Message memory message = _wormholeRelayerMock.lastSent();

        assertEq(ETHEREUM_BID, message.targetChain);
        assertEq(address(_bridge), message.targetAddress);
        assertEq(
            message.payload,
            MessageTransfer({
                assetType: AssetType.XFT,
                assetHash: _asset.hash(),
                to: address(0xa11ce),
                params: TransferParamsFT(100, 18).encode(),
                nonce: 1
            }).encode()
        );
    }

    function test_should_not_be_able_to_transfer_out_xerc20_with_invalid_params() public {
        // define the transfer
        Transfer memory transfer = Transfer({
            assetType: AssetType.XFT,
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

    function test_should_be_able_to_transfer_in_xerc20() public {
        // trigger the asset release
        _mockReceive(
            MessageTransfer({
                assetType: AssetType.XFT,
                assetHash: _asset.hash(),
                to: address(0xa11ce),
                params: TransferParamsFT(100, 18).encode(),
                nonce: 1
            })
        );

        // verify the release
        assertEq(0, _xerc20.balanceOf(address(this)));
        assertEq(0, _xerc20.balanceOf(address(_adapter)));
        assertEq(100, _xerc20.balanceOf(address(0xa11ce)));
    }

    function test_should_be_able_to_transfer_out_xerc20_with_custom_decimals() public {
        // mint some ERC20
        _xerc20.mint(address(this), 100);

        // define the transfer
        Transfer memory transfer = Transfer({
            assetType: AssetType.XFT,
            assetHash: _asset.hash(),
            from: address(this),
            to: address(0xa11ce),
            chainBid: ETHEREUM_BID,
            params: TransferParamsFT(1, 17).encode(),
            nonce: 1
        });

        // execute the transfer
        _bridge.transfer(transfer, "");

        // assert the transfer
        assertEq(90, _xerc20.balanceOf(address(this)));
        assertEq(0, _xerc20.balanceOf(address(_adapter)));
        assertEq(0, _xerc20.balanceOf(address(_bridge)));
        assertEq(0, _xerc20.balanceOf(address(0xa11ce)));

        // assert the message transfer
        WormholeRelayerMock.Message memory message = _wormholeRelayerMock.lastSent();

        assertEq(ETHEREUM_BID, message.targetChain);
        assertEq(address(_bridge), message.targetAddress);
        assertEq(
            message.payload,
            MessageTransfer({
                assetType: AssetType.XFT,
                assetHash: _asset.hash(),
                to: address(0xa11ce),
                params: TransferParamsFT(1, 17).encode(),
                nonce: 1
            }).encode()
        );
    }

    function test_should_be_able_to_transfer_in_xerc20_with_custom_decimals() public {
        // trigger the asset release
        _mockReceive(
            MessageTransfer({
                assetType: AssetType.XFT,
                assetHash: _asset.hash(),
                to: address(0xa11ce),
                params: TransferParamsFT(100, 20).encode(),
                nonce: 1
            })
        );

        // verify the release
        assertEq(0, _xerc20.balanceOf(address(this)));
        assertEq(0, _xerc20.balanceOf(address(_adapter)));
        assertEq(0, _xerc20.balanceOf(address(_bridge)));
        assertEq(1, _xerc20.balanceOf(address(0xa11ce)));
    }

    function test_should_revert_transfer_out_xerc20_with_rest() public {
        // define the transfer
        Transfer memory transfer = Transfer({
            assetType: AssetType.XFT,
            assetHash: _asset.hash(),
            from: address(this),
            to: address(0xa11ce),
            chainBid: ETHEREUM_BID,
            params: TransferParamsFT(1234, 20).encode(), // rest 34
            nonce: 1
        });

        // execute the transfer
        vm.expectRevert(abi.encodeWithSelector(LibReplica.LibReplica_InvalidTransferAmount.selector, 1234, 20, 34));

        _bridge.transfer(transfer, "");
    }
}
