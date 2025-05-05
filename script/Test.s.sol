// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {Script, console} from "forge-std/Script.sol";
import {Bridge, IBridge} from "../src/bridge/Bridge.sol";
import {Asset, AssetType} from "../src/types/Asset.sol";
import {MetadataFT} from "../src/types/MetadataFT.sol";
import {LAYERZERO_RELAYER_CLASS} from "../src/utils/RelayerClasses.sol";
import {Transfer} from "../src/types/Transfer.sol";
import {TransferParamsFT} from "../src/types/TransferParamsFT.sol";
import {ERC20Mock} from "../test/utils/ERC20Mock.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract TestScript is Script {
    bytes32 private constant PERMIT_TYPEHASH =
        keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");

    Bridge public bridge;

    function setUp() public {}

    function run() public {
        bridge = Bridge(0xF6eFdBC0f3c4553F94E8f2F7013a1818B6073ed2);

        vm.startBroadcast();

        address token = 0x07B0b756c0dE60A008EDa03Ff01FEcAD8b0C1141;
        address owner = 0xcA379F93332bAFe1ec1B1bFa7D01E459dc204C25;
        address spender = 0x1F919541B81Fa8664DBcDC38c9c8845FAe042a6D;
        uint256 nonce = 0;
        uint256 deadline = 1742473075;
        uint256 value = 1000000000000000000;

        // hash of permit
        bytes32 permitStructHash = keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, value, nonce, deadline));
        bytes32 permitHash = ERC20Mock(token).hash(permitStructHash);
        (
            ,
            string memory domain_name,
            string memory domain_version,
            uint256 domain_chainId,
            address domain_verifyingContract,
            bytes32 domain_salt,
        ) = ERC20Mock(token).eip712Domain();

        IBridge.Permit memory permit = IBridge.Permit({
            token: token,
            deadline: deadline,
            r: 0xd76137e37bf244933225da185eef5f4a266dfa99f0d4fdba58b2c1f376f026c5,
            s: 0x76204dc84a56ceaf2c6d778cb21bebe78d454e66206b988aab9a9fc11fca4ec5,
            v: 27,
            value: 1000000000000000000
        });

        address signer = ECDSA.recover(permitHash, permit.v, permit.r, permit.s);

        console.log("token:");
        console.logAddress(token);
        console.log("owner:");
        console.logAddress(owner);
        console.log("spender:");
        console.logAddress(spender);
        console.log("nonce:");
        console.logUint(nonce);
        console.log("deadline:");
        console.logUint(deadline);
        console.log("value:");
        console.logUint(value);

        console.log("domain_name:");
        console.logString(domain_name);
        console.log("domain_version:");
        console.logString(domain_version);
        console.log("domain_chainId:");
        console.logUint(domain_chainId);
        console.log("domain_verifyingContract:");
        console.logAddress(domain_verifyingContract);
        console.log("domain_salt:");
        console.logBytes32(domain_salt);

        console.log("permitStructHash:");
        console.logBytes32(permitStructHash);
        console.log("permitHash:");
        console.logBytes32(permitHash);

        console.log("permit.r:");
        console.logBytes32(permit.r);
        console.log("permit.s:");
        console.logBytes32(permit.s);
        console.log("permit.v:");
        console.logUint(permit.v);

        console.log("signer:");
        console.logAddress(signer);

        vm.stopBroadcast();
    }
}
