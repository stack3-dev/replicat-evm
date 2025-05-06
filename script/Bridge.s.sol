// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {Script, console} from "forge-std/Script.sol";
import {Bridge} from "../src/bridge/Bridge.sol";
import {Asset, AssetType} from "../src/types/Asset.sol";
import {MetadataFT} from "../src/types/MetadataFT.sol";
import {LAYERZERO_RELAYER_CLASS} from "../src/utils/RelayerClasses.sol";
import {Transfer} from "../src/types/Transfer.sol";
import {TransferParamsFT} from "../src/types/TransferParamsFT.sol";
import {CREATE_BRIDGE_SALT} from "../src/utils/CreateSalt.sol";
import {BridgeDeployer} from "../src/bridge/BridgeDeployer.sol";

contract BridgeScript is Script {
    function setUp() public {}

    function deploy(
        address initialOwner,
        uint16 wormholeChainId,
        address wormholeRelayer
    ) public {
        vm.startBroadcast();

        BridgeDeployer bridgeDeployer = new BridgeDeployer{
            salt: CREATE_BRIDGE_SALT
        }(initialOwner);

        bridgeDeployer.deploy(wormholeChainId, wormholeRelayer);

        vm.stopBroadcast();
    }

    function createReplicaERC20(
        address bridge_,
        uint16 chainBid,
        address assetAddress,
        string memory name,
        string memory symbol,
        uint8 decimals
    ) public {
        Bridge bridge = Bridge(bridge_);

        vm.startBroadcast();

        bridge.createReplica(
            Asset({
                type_: AssetType.FT,
                chainBid: chainBid,
                address_: assetAddress,
                metadata: MetadataFT({
                    name: name,
                    symbol: symbol,
                    decimals: decimals
                }).encode()
            }),
            ""
        );

        vm.stopBroadcast();
    }

    function createReplicaERC20Adapter(
        address bridge_,
        uint16 chainBid,
        address assetAddress,
        string memory name,
        string memory symbol,
        uint8 decimals
    ) public {
        Bridge bridge = Bridge(bridge_);

        vm.startBroadcast();

        bridge.createReplicaAdapter(
            Asset({
                type_: AssetType.FT,
                chainBid: chainBid,
                address_: assetAddress,
                metadata: MetadataFT({
                    name: name,
                    symbol: symbol,
                    decimals: decimals
                }).encode()
            })
        );

        vm.stopBroadcast();
    }

    function sendERC20(
        Bridge bridge_,
        bytes32 assetHash,
        address fromAddress,
        uint16 toChainBid,
        address toAddress,
        uint256 amount,
        uint8 decimals,
        uint256 nonce,
        uint256 value
    ) public payable {
        Bridge bridge = Bridge(bridge_);

        Transfer memory transfer = Transfer({
            assetType: AssetType.FT,
            assetHash: assetHash,
            from: fromAddress,
            to: toAddress,
            chainBid: toChainBid,
            params: TransferParamsFT(amount, decimals).encode(),
            nonce: nonce
        });

        vm.startBroadcast();

        bridge.transfer{value: value}(transfer, "");

        vm.stopBroadcast();
    }
}
