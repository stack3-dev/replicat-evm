// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {Test, console} from "forge-std/Test.sol";
import {BridgeBaseTest} from "./BridgeBase.t.sol";

import {IBridge, Bridge} from "../../src/bridge/Bridge.sol";
import {WormholeMessenger} from "../../src/bridge/WormholeMessenger.sol";
import {Asset} from "../../src/types/Asset.sol";
import {AssetType} from "../../src/types/AssetType.sol";
import {MetadataFT} from "../../src/types/MetadataFT.sol";
import {TransferParamsFT} from "../../src/types/TransferParamsFT.sol";
import {RFT} from "../../src/assets/ft/RFT.sol";
import {ERC20Mock} from "../utils/ERC20Mock.sol";
import {Transfer} from "../../src/types/Transfer.sol";
import {MessageTransfer} from "../../src/types/MessageTransfer.sol";
import {LibAddress} from "../../src/libraries/LibAddress.sol";
import {FOUNDRY_BID, ETHEREUM_BID} from "../../src/utils/BridgeChains.sol";
import {ECDSA} from "openzeppelin-contracts/contracts/utils/cryptography/ECDSA.sol";

bytes4 constant MOCK_BRIDGE_CLASS = bytes4(keccak256("MOCK"));
bytes32 constant PERMIT_TYPEHASH =
    keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");

uint256 constant TRANSFER_COST = 100;

contract BridgeCommonTest is BridgeBaseTest {
    using ECDSA for bytes32;
    using LibAddress for address;

    ERC20Mock public _erc20;
    Asset public _asset;

    function _setUp() internal override {
        _wormholeRelayerMock.setCost(TRANSFER_COST);

        // instiate an ERC20
        _erc20 = new ERC20Mock("ERC20Mock", "MCK");
        _erc20.mint(address(this), 100);

        // create adapter
        _asset = Asset({
            type_: AssetType.FT,
            chainBid: FOUNDRY_BID,
            address_: address(_erc20),
            metadata: MetadataFT({name: "ERC20Mock", symbol: "MCK", decimals: 18}).encode()
        });

        address adapter = _bridge.createReplicaAdapter(_asset);

        // approve the bridge to transfer the asset
        _erc20.approve(adapter, UINT256_MAX);
    }

    function test_should_be_able_to_retreive_transfer_sequence() public {
        // define the transfer
        Transfer memory transfer = Transfer({
            assetType: AssetType.FT,
            assetHash: _asset.hash(),
            from: address(this),
            to: address(this),
            chainBid: ETHEREUM_BID,
            params: TransferParamsFT(100, 18).encode(),
            nonce: 1
        });

        // execute the transfer
        _bridge.transfer{value: TRANSFER_COST}(transfer, "");

        // retreive transfer status
        uint64 sequence = _bridge.getTransferSequence(_bridge.hash(transfer.hash()));

        // assert the transfer sequence
        assertEq(sequence, _wormholeRelayerMock.lastSequence());
    }

    function test_should_be_able_to_transfer_with_signature() public {
        // instantiate a signer
        uint256 signerPk = 0xa11ce;
        address signer = vm.addr(signerPk);

        // found the signer
        _erc20.mint(signer, 100);

        // signe permit
        address adapter = _bridge.computeReplicaAddress(_asset);
        vm.startPrank(signer);
        (uint8 v, bytes32 r, bytes32 s) = _getPermitSignature(signerPk, signer, adapter, 80, 0, UINT256_MAX);
        vm.stopPrank();

        _erc20.permit(signer, adapter, 80, UINT256_MAX, v, r, s);

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
        (v, r, s) = vm.sign(signerPk, transferHash);
        bytes memory signature = abi.encodePacked(r, s, v);
        vm.stopPrank();

        // execute the transfer
        _bridge.transfer{value: TRANSFER_COST}(transfer, signature);

        // assert the transfer
        assertEq(20, _erc20.balanceOf(address(signer)));
        assertEq(80, _erc20.balanceOf(address(adapter)));
    }

    function test_should_revert_transfer_with_bad_signature() public {
        // instantiate a signer
        uint256 signerPk = 0xa11ce;
        address signer = vm.addr(signerPk);

        // found the signer
        _erc20.mint(signer, 100);

        // signe permit
        vm.startPrank(signer);
        (uint8 v, bytes32 r, bytes32 s) = _getPermitSignature(signerPk, signer, address(_bridge), 80, 0, UINT256_MAX);
        vm.stopPrank();

        _erc20.permit(signer, address(_bridge), 80, UINT256_MAX, v, r, s);

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
        vm.startPrank(signer);
        (v, r, s) = vm.sign(signerPk, transfer.hash()); // Bad hash injected here
        bytes memory signature = abi.encodePacked(r, s, v);
        vm.stopPrank();

        // execute the transfer
        vm.expectRevert(
            abi.encodeWithSelector(
                IBridge.Bridge_InvalidSignature.selector, address(signer), _bridge.hash(transfer.hash()), signature
            )
        );
        _bridge.transfer{value: TRANSFER_COST}(transfer, signature);
    }

    function test_should_not_be_able_to_transfer_with_invalid_nonce() public {
        // define the transfer
        Transfer memory transfer = Transfer({
            assetType: AssetType.FT,
            assetHash: _asset.hash(),
            from: address(this),
            to: address(this),
            chainBid: ETHEREUM_BID,
            params: TransferParamsFT(50, 18).encode(),
            nonce: 1
        });

        // execute the transfer
        _bridge.transfer{value: TRANSFER_COST}(transfer, "");

        // send the same transfer again
        vm.expectRevert(
            abi.encodeWithSelector(IBridge.Bridge_TransferAlreadyProcessed.selector, _bridge.hash(transfer.hash()))
        );
        _bridge.transfer{value: TRANSFER_COST}(transfer, "");
    }

    function test_should_not_be_able_to_transfer_with_invalid_to_chain() public {
        // define the transfer
        Transfer memory transfer = Transfer({
            assetType: AssetType.FT,
            assetHash: _asset.hash(),
            from: address(this),
            to: address(this),
            chainBid: FOUNDRY_BID, // invalid chain (cannot be the current chain)
            params: TransferParamsFT(100, 18).encode(),
            nonce: 1
        });

        // execute the transfer
        vm.expectRevert(abi.encodeWithSelector(IBridge.Bridge_InvalidChainBid.selector, transfer.chainBid));
        _bridge.transfer{value: TRANSFER_COST}(transfer, "");
    }

    function test_should_not_be_able_to_receive_transfer_with_invalid_from_address() public {
        // trigger the asset release
        vm.expectRevert(
            abi.encodeWithSelector(WormholeMessenger.WormholeMessenger_InvalidForeignRelayer.selector, address(this))
        );

        _wormholeRelayerMock.mockReceive(
            _bridge,
            MessageTransfer({
                assetType: AssetType.FT,
                assetHash: _asset.hash(),
                to: address(0xa11ce),
                params: TransferParamsFT(100, 18).encode(),
                nonce: 1
            }).encode(),
            address(this), // invalid from address, bridge expected here
            ETHEREUM_BID
        );
    }

    function test_should_not_be_able_to_receive_transfer_with_invalid_from_invalid_relayer() public {
        bytes[] memory empty = new bytes[](0);

        vm.expectRevert(
            abi.encodeWithSelector(WormholeMessenger.WormholeMessenger_UnauthorizedCaller.selector, address(this))
        );
        _bridge.receiveWormholeMessages(
            MessageTransfer({
                assetType: AssetType.FT,
                assetHash: _asset.hash(),
                to: address(0xa11ce),
                params: TransferParamsFT(100, 18).encode(),
                nonce: 1
            }).encode(),
            empty,
            address(_bridge).toBytes32(),
            ETHEREUM_BID,
            keccak256("MOCK")
        );
    }

    function test_should_collect_transfer_fee() public {
        // set creation fee
        _bridge.setFactoryFee(100);

        // mock erc20

        ERC20Mock erc20Bis = new ERC20Mock("ERC20MockBis", "MCK");

        // create a new asset
        Asset memory asset = Asset({
            type_: AssetType.FT,
            chainBid: FOUNDRY_BID,
            address_: address(erc20Bis),
            metadata: MetadataFT({name: "ERC20MockBis", symbol: "MCK", decimals: 18}).encode()
        });
        _bridge.createReplicaAdapter{value: 100}(asset);

        // check balance of smart contract
        assertEq(address(_bridge).balance, 100);

        // withdraw the balance
        _bridge.withdrawTransferFees(payable(address(0xa11c3)));

        // check balance of smart contract and receiver
        assertEq(address(_bridge).balance, 0);
        assertEq(address(0xa11c3).balance, 100);
        assertEq(address(_wormholeRelayerMock).balance, 0);
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
}
