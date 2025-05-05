// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {Test, console} from "forge-std/Test.sol";
import {BridgeBaseTest} from "./BridgeBase.t.sol";
import {IBridge, Bridge, Ownable} from "../../src/bridge/Bridge.sol";
import {Asset} from "../../src/types/Asset.sol";
import {AssetType} from "../../src/types/AssetType.sol";
import {ETHEREUM_BID, BASE_BID, FOUNDRY_BID} from "../../src/utils/BridgeChains.sol";
import {MetadataFT} from "../../src/types/MetadataFT.sol";
import {MetadataNFT} from "../../src/types/MetadataNFT.sol";
import {RFT} from "../../src/assets/ft/RFT.sol";
import {Transfer} from "../../src/types/Transfer.sol";
import {TransferParamsFT} from "../../src/types/TransferParamsFT.sol";

bytes4 constant MOCK_BRIDGE_CLASS = bytes4(keccak256("MOCK"));

contract BridgeTest is BridgeBaseTest {
    function test_should_be_owned() public view {
        address owner = _bridge.owner();
        assertEq(owner, address(this));
    }

    function test_should_be_able_to_set_owner() public {
        _bridge.transferOwnership(address(0x123));
        address owner = _bridge.owner();
        assertEq(owner, address(0x123));
    }

    function test_should_not_allow_non_owner_to_set_owner() public {
        _bridge.transferOwnership(address(0x123));
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, address(this)));
        _bridge.transferOwnership(address(0x456));
    }

    function test_should_set_factory_Fee() public {
        _bridge.setFactoryFee(10_000);
        uint256 factoryFee = _bridge.getFactoryFee();
        assertEq(factoryFee, 10_000);
    }

    // more tests on ReplicaFactory.t.sol
    function test_should_create_replica() public {
        Asset memory assetA = Asset({
            type_: AssetType.FT,
            chainBid: ETHEREUM_BID,
            address_: address(1337),
            metadata: MetadataFT({name: "Test", symbol: "TST", decimals: 18}).encode()
        });
        address replicaAddressA = _bridge.createReplica(assetA, "");

        bytes32 assetHash = assetA.hash();
        assertNotEq(replicaAddressA, address(0));
        assertEq(RFT(replicaAddressA).assetHash(), assetHash);
    }

    function test_should_quote_transfer() public {
        _wormholeRelayerMock.setCost(12_345);
        // quote the transfer
        uint256 quote = _bridge.quoteTransfer(ETHEREUM_BID);
        assertEq(quote, 12_345);
    }

    function test_should_return_chain_bid() public view {
        uint256 chainBid = _bridge.chainBid();
        assertEq(chainBid, FOUNDRY_BID);
    }
}
