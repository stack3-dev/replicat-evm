// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {Test, console} from "forge-std/Test.sol";
import {BridgeBaseTest} from "./BridgeBase.t.sol";

import {Bridge, IBridge} from "../../src/bridge/Bridge.sol";
import {Asset} from "../../src/types/Asset.sol";
import {AssetType} from "../../src/types/AssetType.sol";
import {MetadataFT} from "../../src/types/MetadataFT.sol";
import {TransferParamsFT} from "../../src/types/TransferParamsFT.sol";
import {ERC20Mock} from "../utils/ERC20Mock.sol";
import {WormholeRelayerMock} from "../utils/WormholeRelayerMock.sol";
import {Transfer} from "../../src/types/Transfer.sol";
import {MessageTransfer} from "../../src/types/MessageTransfer.sol";
import {FOUNDRY_BID, ETHEREUM_BID} from "../../src/utils/BridgeChains.sol";
import {ECDSA} from "openzeppelin-contracts/contracts/utils/cryptography/ECDSA.sol";
import {ERC20Adapter} from "../../src/assets/ft/ERC20Adapter.sol";
import {LibReplica} from "../../src/libraries/LibReplica.sol";

bytes4 constant MOCK_BRIDGE_CLASS = bytes4(keccak256("MOCK"));
bytes32 constant PERMIT_TYPEHASH =
    keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");

contract BridgeTransfeERC20AdapterTest is BridgeBaseTest {
    ERC20Mock public _erc20;
    Asset public _asset;
    ERC20Adapter public _adapter;

    function _setUp() internal override {
        // instantiate an ERC20
        _erc20 = new ERC20Mock("ERC20Mock", "MCK");

        // create adapter
        _asset = Asset({
            type_: AssetType.FT,
            chainBid: FOUNDRY_BID,
            address_: address(_erc20),
            metadata: MetadataFT({name: "ERC20Mock", symbol: "MCK", decimals: 18}).encode()
        });
        _adapter = ERC20Adapter(_bridge.createReplicaAdapter(_asset));

        // approve the adapter to transfer ERC20
        _erc20.approve(address(_adapter), UINT256_MAX);
    }

    function test_should_be_able_to_transfer_out_erc20() public {
        // mint some ERC20
        _erc20.mint(address(this), 100);

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
        _bridge.transfer(transfer, "");

        // assert the transfer
        assertEq(0, _erc20.balanceOf(address(this)));
        assertEq(100, _erc20.balanceOf(address(_adapter)));
        assertEq(0, _erc20.balanceOf(address(_bridge)));
        assertEq(0, _erc20.balanceOf(address(0xa11ce)));

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

    function test_should_not_be_able_to_transfer_out_erc20_with_invalid_params() public {
        // define the transfer
        Transfer memory transfer = Transfer({
            assetType: AssetType.FT,
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

    function test_should_be_able_to_transfer_in_erc20() public {
        // lock some ERC20 in treasury
        test_should_be_able_to_transfer_out_erc20();

        // trigger the asset release
        _mockReceive(
            MessageTransfer({
                assetType: AssetType.FT,
                assetHash: _asset.hash(),
                to: address(0xa11ce),
                params: TransferParamsFT(100, 18).encode(),
                nonce: 1
            })
        );

        // verify the release
        assertEq(0, _erc20.balanceOf(address(this)));
        assertEq(0, _erc20.balanceOf(address(_adapter)));
        assertEq(0, _erc20.balanceOf(address(_bridge)));
        assertEq(100, _erc20.balanceOf(address(0xa11ce)));
    }

    function test_should_be_able_to_transfer_out_erc20_with_permit() public {
        // instantiate a signer
        uint256 signerPk = 0xa11ce;
        address signer = vm.addr(signerPk);

        // found the signer
        _erc20.mint(signer, 100);

        // signe permit
        vm.startPrank(signer);
        (uint8 v, bytes32 r, bytes32 s) = _getPermitSignature(signerPk, signer, address(_adapter), 80, 0, UINT256_MAX);
        vm.stopPrank();

        // define the transfer
        Transfer memory transfer = Transfer({
            assetType: AssetType.FT,
            assetHash: _asset.hash(),
            from: address(signer),
            to: address(this),
            chainBid: ETHEREUM_BID,
            params: TransferParamsFT(80, 18).encode(),
            nonce: 1
        });

        // sign the transfer
        bytes32 transferHash = _bridge.hash(transfer.hash());

        vm.startPrank(signer);
        (uint8 vt, bytes32 rt, bytes32 st) = vm.sign(signerPk, transferHash);
        bytes memory signature = abi.encodePacked(rt, st, vt);
        vm.stopPrank();

        // execute the transfer
        _bridge.transferWithPermit(transfer, signature, IBridge.Permit(address(_erc20), 80, UINT256_MAX, v, r, s));

        // assert the transfer
        assertEq(20, _erc20.balanceOf(address(signer)));
        assertEq(80, _erc20.balanceOf(address(_adapter)));
    }

    function _getPermitSignature(
        uint256 signerPrivateKey,
        address owner,
        address spender,
        uint256 value,
        uint256 nonce,
        uint256 deadline
    ) private view returns (uint8, bytes32, bytes32) {
        bytes32 structHash = keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, value, nonce, deadline));

        bytes32 digest = _erc20.hash(structHash);
        return vm.sign(signerPrivateKey, digest);
    }

    function test_should_be_able_to_transfer_out_erc20_with_custom_decimals() public {
        // mint some ERC20
        _erc20.mint(address(this), 100);

        // define the transfer
        Transfer memory transfer = Transfer({
            assetType: AssetType.FT,
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
        assertEq(90, _erc20.balanceOf(address(this)));
        assertEq(10, _erc20.balanceOf(address(_adapter)));
        assertEq(0, _erc20.balanceOf(address(_bridge)));
        assertEq(0, _erc20.balanceOf(address(0xa11ce)));

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
                params: TransferParamsFT(1, 17).encode(),
                nonce: 1
            }).encode()
        );
    }

    function test_should_be_able_to_transfer_in_erc20_with_custom_decimals() public {
        // lock some ERC20 in treasury
        test_should_be_able_to_transfer_out_erc20();

        // trigger the asset release
        _mockReceive(
            MessageTransfer({
                assetType: AssetType.FT,
                assetHash: _asset.hash(),
                to: address(0xa11ce),
                params: TransferParamsFT(100, 20).encode(),
                nonce: 1
            })
        );

        // verify the release
        assertEq(0, _erc20.balanceOf(address(this)));
        assertEq(99, _erc20.balanceOf(address(_adapter)));
        assertEq(0, _erc20.balanceOf(address(_bridge)));
        assertEq(1, _erc20.balanceOf(address(0xa11ce)));
    }

    function test_should_revert_transfer_out_erc20_with_rest() public {
        // define the transfer
        Transfer memory transfer = Transfer({
            assetType: AssetType.FT,
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
