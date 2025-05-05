// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {Script, console} from "forge-std/Script.sol";
import {Bridge} from "../src/bridge/Bridge.sol";

import {Asset, AssetType} from "../src/types/Asset.sol";
import {MetadataFT} from "../src/types/MetadataFT.sol";
import {Transfer} from "../src/types/Transfer.sol";
import {TransferParamsFT} from "../src/types/TransferParamsFT.sol";
import {ERC20Mock} from "../test/utils/ERC20Mock.sol";

contract UtilsScript is Script {
    function setUp() public {}

    function run() public {
        console.log("Link Asset Hash");
        console.logBytes32(
            Asset({
                type_: AssetType.FT,
                chainBid: 11155111,
                address_: address(0x779877A7B0D9E8603169DdbD7836e478b4624789),
                metadata: MetadataFT("Test", "TST", 20).encode()
            }).hash()
        );

        console.log("bytes 0");
        console.logBytes(new bytes(0));

        console.log("Param encode");
        console.logBytes(TransferParamsFT(15, 18).encode());
    }

    function createERC20Mock(string memory name, string memory symbol) public {
        vm.startBroadcast();

        ERC20Mock erc20 = new ERC20Mock(name, symbol);

        vm.stopBroadcast();
    }
}
