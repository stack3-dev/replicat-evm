// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {Test, console} from "forge-std/Test.sol";
import {ERC721Holder} from "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import {IERC721Metadata} from "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {IERC1155MetadataURI} from "@openzeppelin/contracts/token/ERC1155/extensions/IERC1155MetadataURI.sol";
import {IXNFT} from "../../src/assets/interfaces/IXNFT.sol";
import {ReplicaFactoryMock} from "../utils/ReplicaFactoryMock.sol";
import {IBridge} from "../../src/bridge/interfaces/IBridge.sol";
import {Bridge} from "../../src/bridge/Bridge.sol";
import {Asset} from "../../src/types/Asset.sol";
import {AssetType} from "../../src/types/AssetType.sol";
import {ETHEREUM_BID, BASE_BID, FOUNDRY_BID} from "../../src/utils/BridgeChains.sol";
import {MetadataFT} from "../../src/types/MetadataFT.sol";
import {MetadataNFT} from "../../src/types/MetadataNFT.sol";
import {IReplica} from "../../src/assets/interfaces/IReplica.sol";
import {RFT} from "../../src/assets/ft/RFT.sol";
import {RNFT} from "../../src/assets/nft/RNFT.sol";
import {ERC20Mock} from "../utils/ERC20Mock.sol";
import {ERC721Mock} from "../utils/ERC721Mock.sol";
import {XERC20Mock} from "../utils/XERC20Mock.sol";
import {XERC721Mock} from "../utils/XERC721Mock.sol";
import {ERC20Adapter} from "../../src/assets/ft/ERC20Adapter.sol";
import {ERC721Adapter} from "../../src/assets/nft/ERC721Adapter.sol";
import {XFTAdapter} from "../../src/assets/ft/XFTAdapter.sol";
import {XNFTAdapter} from "../../src/assets/nft/XNFTAdapter.sol";
import {Replica} from "../../src/assets/Replica.sol";
import {LibAssetCreateReplica} from "../../src/libraries/LibAssetCreateReplica.sol";
import {LibAssetCreateReplicaAdapter} from "../../src/libraries/LibAssetCreateReplicaAdapter.sol";
import {WormholeRelayerMock} from "../utils/WormholeRelayerMock.sol";

contract ReplicaFactoryTest is Test, ERC721Holder {
    ReplicaFactoryMock public _factory;
    Bridge public _bridge;

    receive() external payable {}

    function setUp() public {
        _bridge = new Bridge(address(this), FOUNDRY_BID, address(new WormholeRelayerMock()));
        // new utils address
        _factory = new ReplicaFactoryMock(_bridge);
    }

    function test_should_create_replica_rft() public {
        // define the assets
        Asset memory assetA = Asset({
            type_: AssetType.FT,
            chainBid: ETHEREUM_BID,
            address_: address(1337),
            metadata: MetadataFT({name: "TestA", symbol: "TSTA", decimals: 18}).encode()
        });

        // precompute the address of the replica
        address computedReplicaAddressA = _factory.computeReplicaAddress(assetA);

        // create the replicas
        address replicaAddressA = _factory.createReplica(assetA, "");

        // assert the replicas addresses matches the computed ones
        assertEq(computedReplicaAddressA, replicaAddressA);

        // assert replica A values
        assertEq(IERC20Metadata(replicaAddressA).name(), "TestA (replicaT)");
        assertEq(IERC20Metadata(replicaAddressA).symbol(), "TSTA");
        assertEq(IERC20Metadata(replicaAddressA).decimals(), 18);
        assertEq(IReplica(replicaAddressA).assetHash(), assetA.hash());
        assertEq(uint8(IReplica(replicaAddressA).asset().type_), uint8(assetA.type_));
        assertEq(IReplica(replicaAddressA).asset().chainBid, assetA.chainBid);
        assertEq(IReplica(replicaAddressA).asset().address_, assetA.address_);
        assertEq(IReplica(replicaAddressA).bridgeAddress(), address(_bridge));
    }

    function test_should_create_replica_erc721() public {
        // define Assets
        Asset memory assetA = Asset({
            type_: AssetType.NFT,
            chainBid: ETHEREUM_BID,
            address_: address(1337),
            metadata: MetadataNFT("TestA721", "TSTA").encode()
        });
        Asset memory assetB = Asset({
            type_: AssetType.NFT,
            chainBid: BASE_BID,
            address_: address(1338),
            metadata: MetadataNFT("TestB721", "TSTB").encode()
        });

        // compute asset addresses
        address computedReplicaAddressA = _factory.computeReplicaAddress(assetA);
        address computedReplicaAddressB = _factory.computeReplicaAddress(assetB);

        // create the replicas
        address replicaAddressA = _factory.createReplica(assetA, abi.encode("tokenURI/"));
        address replicaAddressB = _factory.createReplica(assetB, abi.encode(""));

        // assert the replicas addresses matches the computed ones
        assertEq(computedReplicaAddressA, replicaAddressA);
        assertEq(computedReplicaAddressB, replicaAddressB);

        assertEq(IERC721Metadata(replicaAddressA).name(), "TestA721 (replicaT)");
        assertEq(IERC721Metadata(replicaAddressA).symbol(), "TSTA");
        assertEq(IReplica(replicaAddressA).assetHash(), assetA.hash());
        assertEq(uint8(IReplica(replicaAddressA).asset().type_), uint8(assetA.type_));
        assertEq(IReplica(replicaAddressA).asset().chainBid, assetA.chainBid);
        assertEq(IReplica(replicaAddressA).asset().address_, assetA.address_);
        assertEq(IReplica(replicaAddressA).bridgeAddress(), address(_bridge));

        assertEq(IERC721Metadata(replicaAddressB).name(), "TestB721 (replicaT)");
        assertEq(IERC721Metadata(replicaAddressB).symbol(), "TSTB");
        assertEq(IReplica(replicaAddressB).assetHash(), assetB.hash());
        assertEq(uint8(IReplica(replicaAddressB).asset().type_), uint8(assetB.type_));
        assertEq(IReplica(replicaAddressB).asset().chainBid, assetB.chainBid);
        assertEq(IReplica(replicaAddressB).asset().address_, assetB.address_);
        assertEq(IReplica(replicaAddressB).bridgeAddress(), address(_bridge));
    }

    function test_should_revert_create_replica_rft_already_exist() public {
        // define the assets
        Asset memory assetErc20 = Asset({
            type_: AssetType.FT,
            chainBid: ETHEREUM_BID,
            address_: address(1337),
            metadata: MetadataFT({name: "Test", symbol: "TST", decimals: 18}).encode()
        });

        // create the replica
        _factory.createReplica(assetErc20, abi.encode(MetadataFT({name: "Test", symbol: "TST", decimals: 18})));

        // expect revert
        vm.expectRevert(bytes4(0x30116425));
        _factory.createReplica(assetErc20, abi.encode(MetadataFT({name: "Test", symbol: "TST", decimals: 18})));
    }

    function test_should_revert_create_replica_rnft_already_exist() public {
        // define the assets
        Asset memory assetErc721 = Asset({
            type_: AssetType.NFT,
            chainBid: ETHEREUM_BID,
            address_: address(1337),
            metadata: MetadataNFT("Test", "TST").encode()
        });

        // create the replica
        _factory.createReplica(assetErc721, "");

        // expect revert
        vm.expectRevert(bytes4(0x30116425));
        _factory.createReplica(assetErc721, "");
    }

    function test_should_revert_create_rft_on_local_chain() public {
        // define the assets
        Asset memory assetErc20 = Asset({
            type_: AssetType.FT,
            chainBid: FOUNDRY_BID,
            address_: address(1337),
            metadata: MetadataFT({name: "Test", symbol: "TST", decimals: 18}).encode()
        });

        // expect revert
        vm.expectRevert(
            abi.encodeWithSelector(LibAssetCreateReplica.LibAssetCreateReplica__InvalidChainBid.selector, FOUNDRY_BID)
        );
        _factory.createReplica(assetErc20, abi.encode(MetadataFT({name: "Test", symbol: "TST", decimals: 18})));
    }

    function test_should_revert_create_rnft_on_local_chain() public {
        // define the assets
        Asset memory assetErc721 = Asset({
            type_: AssetType.NFT,
            chainBid: FOUNDRY_BID,
            address_: address(1337),
            metadata: MetadataNFT("Test", "TST").encode()
        });

        // expect revert
        vm.expectRevert(
            abi.encodeWithSelector(LibAssetCreateReplica.LibAssetCreateReplica__InvalidChainBid.selector, FOUNDRY_BID)
        );
        _factory.createReplica(assetErc721, "");
    }

    function test_should_create_erc20_adapter() public {
        // create mocks
        ERC20Mock erc20 = new ERC20Mock("TestA", "TSTA");

        // define the assets
        Asset memory assetA = Asset({
            type_: AssetType.FT,
            chainBid: FOUNDRY_BID,
            address_: address(erc20),
            metadata: MetadataFT({name: "TestA", symbol: "TSTA", decimals: 18}).encode()
        });

        // precompute the address of the replica
        address computedReplicaAddressA = _factory.computeReplicaAddress(assetA);

        // create the replicas
        address replicaAddressA = _factory.createReplicaAdapter(assetA);

        // assert the replicas addresses matches the computed ones
        assertEq(computedReplicaAddressA, replicaAddressA);

        // assert replica A values
        assertEq(IReplica(replicaAddressA).assetHash(), assetA.hash());
        assertEq(uint8(IReplica(replicaAddressA).asset().type_), uint8(assetA.type_));
        assertEq(IReplica(replicaAddressA).asset().chainBid, assetA.chainBid);
        assertEq(IReplica(replicaAddressA).asset().address_, assetA.address_);
        assertEq(IReplica(replicaAddressA).bridgeAddress(), address(_bridge));
    }

    function test_should_revert_create_erc20_adapter_already_exist() public {
        // create mocks
        ERC20Mock erc20A = new ERC20Mock("TestA", "TSTA");

        // define the assets
        Asset memory assetA = Asset({
            type_: AssetType.FT,
            chainBid: FOUNDRY_BID,
            address_: address(erc20A),
            metadata: MetadataFT({name: "TestA", symbol: "TSTA", decimals: 18}).encode()
        });

        // create the replica
        _factory.createReplicaAdapter(assetA);

        // expect revert
        vm.expectRevert(bytes4(0x30116425));
        _factory.createReplicaAdapter(assetA);
    }

    function test_should_revert_create_erc20_adapter_on_foreing_chain() public {
        // create mocks
        ERC20Mock erc20A = new ERC20Mock("TestA", "TSTA");

        // define the assets
        Asset memory assetA = Asset({
            type_: AssetType.FT,
            chainBid: ETHEREUM_BID,
            address_: address(erc20A),
            metadata: MetadataFT({name: "TestA", symbol: "TSTA", decimals: 18}).encode()
        });

        // expect revert
        vm.expectRevert(
            abi.encodeWithSelector(
                LibAssetCreateReplicaAdapter.LibAssetCreateReplicaAdapter__InvalidChainBid.selector,
                ETHEREUM_BID,
                FOUNDRY_BID
            )
        );
        _factory.createReplicaAdapter(assetA);
    }

    function test_should_create_erc721_adapter() public {
        // create mocks
        ERC721Mock erc721 = new ERC721Mock("TestA", "TSTA");

        // define the assets
        Asset memory assetA = Asset({
            type_: AssetType.NFT,
            chainBid: FOUNDRY_BID,
            address_: address(erc721),
            metadata: MetadataNFT("TestA", "TSTA").encode()
        });

        // precompute the address of the replica
        address computedReplicaAddressA = _factory.computeReplicaAddress(assetA);

        // create the replicas
        address replicaAddressA = _factory.createReplicaAdapter(assetA);

        // assert the replicas addresses matches the computed ones
        assertEq(computedReplicaAddressA, replicaAddressA);

        // assert replica A values
        assertEq(IReplica(replicaAddressA).assetHash(), assetA.hash());
        assertEq(uint8(IReplica(replicaAddressA).asset().type_), uint8(assetA.type_));
        assertEq(IReplica(replicaAddressA).asset().chainBid, assetA.chainBid);
        assertEq(IReplica(replicaAddressA).asset().address_, assetA.address_);
        assertEq(IReplica(replicaAddressA).bridgeAddress(), address(_bridge));
    }

    function test_should_revert_create_erc721_adapter_already_exist() public {
        // create mocks
        ERC721Mock erc721 = new ERC721Mock("TestA", "TSTA");

        // define the assets
        Asset memory assetA = Asset({
            type_: AssetType.NFT,
            chainBid: FOUNDRY_BID,
            address_: address(erc721),
            metadata: MetadataNFT("TestA", "TSTA").encode()
        });

        // create the replica
        _factory.createReplicaAdapter(assetA);

        // expect revert
        vm.expectRevert(bytes4(0x30116425));
        _factory.createReplicaAdapter(assetA);
    }

    function test_should_revert_create_erc721_adapter_on_foreing_chain() public {
        // create mocks
        ERC721Mock erc721 = new ERC721Mock("TestA", "TSTA");

        // define the assets
        Asset memory assetA = Asset({
            type_: AssetType.NFT,
            chainBid: ETHEREUM_BID,
            address_: address(erc721),
            metadata: MetadataNFT("TestA", "TSTA").encode()
        });

        // expect revert
        vm.expectRevert(
            abi.encodeWithSelector(
                LibAssetCreateReplicaAdapter.LibAssetCreateReplicaAdapter__InvalidChainBid.selector,
                ETHEREUM_BID,
                FOUNDRY_BID
            )
        );
        _factory.createReplicaAdapter(assetA);
    }

    function test_should_create_xft_adapter() public {
        // create mocks
        XERC20Mock xerc20 = new XERC20Mock("TestA", "TSTA", address(this));

        // define the assets
        Asset memory assetA = Asset({
            type_: AssetType.XFT,
            chainBid: 0,
            address_: address(xerc20),
            metadata: MetadataFT("TestA", "TSTA", 18).encode()
        });

        // precompute the address of the replica
        address computedReplicaAddressA = _factory.computeReplicaAddress(assetA);

        // create the replicas
        address replicaAddressA = _factory.createReplicaAdapter(assetA);

        // assert the replicas addresses matches the computed ones
        assertEq(computedReplicaAddressA, replicaAddressA);

        // assert replica A values
        assertEq(IReplica(replicaAddressA).assetHash(), assetA.hash());
        assertEq(uint8(IReplica(replicaAddressA).asset().type_), uint8(assetA.type_));
        assertEq(IReplica(replicaAddressA).asset().chainBid, assetA.chainBid);
        assertEq(IReplica(replicaAddressA).asset().address_, assetA.address_);
        assertEq(IReplica(replicaAddressA).bridgeAddress(), address(_bridge));
    }

    function test_should_revert_create_xft_adapter_already_exist() public {
        XERC20Mock xerc20 = new XERC20Mock("TestA", "TSTA", address(this));

        // define the assets
        Asset memory assetA = Asset({
            type_: AssetType.XFT,
            chainBid: 0,
            address_: address(xerc20),
            metadata: MetadataFT("TestA", "TSTA", 18).encode()
        });

        // create the replica
        _factory.createReplicaAdapter(assetA);

        // expect revert
        vm.expectRevert(bytes4(0x30116425));
        _factory.createReplicaAdapter(assetA);
    }

    function test_should_revert_create_xft_adapter_with_non_zero_chainbid() public {
        XERC20Mock xerc20 = new XERC20Mock("TestA", "TSTA", address(this));

        // define the assets
        Asset memory assetA = Asset({
            type_: AssetType.XFT,
            chainBid: 1,
            address_: address(xerc20),
            metadata: MetadataNFT("TestA", "TSTA").encode()
        });

        // expect revert
        vm.expectRevert(
            abi.encodeWithSelector(
                LibAssetCreateReplicaAdapter.LibAssetCreateReplicaAdapter__InvalidChainBid.selector, 1, 0
            )
        );
        _factory.createReplicaAdapter(assetA);
    }

    function test_should_create_xnft_adapter() public {
        XERC721Mock xerc721 = new XERC721Mock("TestA", "TSTA", address(this));

        // define the assets
        Asset memory assetA = Asset({
            type_: AssetType.XNFT,
            chainBid: 0,
            address_: address(xerc721),
            metadata: MetadataNFT("TestA", "TSTA").encode()
        });

        // precompute the address of the replica
        address computedReplicaAddressA = _factory.computeReplicaAddress(assetA);

        // create the replicas
        address replicaAddressA = _factory.createReplicaAdapter(assetA);

        // assert the replicas addresses matches the computed ones
        assertEq(computedReplicaAddressA, replicaAddressA);

        // assert replica A values
        assertEq(IReplica(replicaAddressA).assetHash(), assetA.hash());
        assertEq(uint8(IReplica(replicaAddressA).asset().type_), uint8(assetA.type_));
        assertEq(IReplica(replicaAddressA).asset().chainBid, assetA.chainBid);
        assertEq(IReplica(replicaAddressA).asset().address_, assetA.address_);
        assertEq(IReplica(replicaAddressA).bridgeAddress(), address(_bridge));
    }

    function test_should_revert_create_xnft_adapter_already_exist() public {
        XERC721Mock xerc721 = new XERC721Mock("TestA", "TSTA", address(this));

        // define the assets
        Asset memory assetA = Asset({
            type_: AssetType.XNFT,
            chainBid: 0,
            address_: address(xerc721),
            metadata: MetadataNFT("TestA", "TSTA").encode()
        });

        // create the replica
        _factory.createReplicaAdapter(assetA);

        // expect revert
        vm.expectRevert(bytes4(0x30116425));
        _factory.createReplicaAdapter(assetA);
    }

    function test_should_revert_create_xnft_adapter_with_non_zero_chainbid() public {
        XERC721Mock xerc721 = new XERC721Mock("TestA", "TSTA", address(this));

        // define the assets
        Asset memory assetA = Asset({
            type_: AssetType.XNFT,
            chainBid: 1,
            address_: address(xerc721),
            metadata: MetadataNFT("TestA", "TSTA").encode()
        });

        // expect revert
        vm.expectRevert(
            abi.encodeWithSelector(
                LibAssetCreateReplicaAdapter.LibAssetCreateReplicaAdapter__InvalidChainBid.selector, 1, 0
            )
        );
        _factory.createReplicaAdapter(assetA);
    }
}
