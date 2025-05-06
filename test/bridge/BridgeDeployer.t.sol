// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {Test, console} from "forge-std/Test.sol";
import {Bridge} from "../../src/bridge/Bridge.sol";
import {BridgeDeployer} from "../../src/bridge/BridgeDeployer.sol";
import {CREATE_BRIDGE_SALT} from "../../src/utils/CreateSalt.sol";
import {FOUNDRY_BID} from "../../src/utils/BridgeChains.sol";

contract BridgeDeployerTest is Test {
    BridgeDeployer public _bridgeDeployer;

    function setUp() public {
        _bridgeDeployer = new BridgeDeployer{salt: CREATE_BRIDGE_SALT}(
            address(this)
        );
    }

    function test_should_deploy_bridge() public {
        address expectedAddress = _bridgeDeployer.bridgeAddress();
        address bridgeAddress = _bridgeDeployer.deploy(
            FOUNDRY_BID,
            address(0xb0b)
        );
        assertEq(bridgeAddress, expectedAddress);
        assertEq(Bridge(bridgeAddress).chainBid(), FOUNDRY_BID);
    }

    function test_should_not_deploy_bridge_twice() public {
        _bridgeDeployer.deploy(FOUNDRY_BID, address(0xb0b));
        vm.expectRevert(bytes4(0x30116425));
        _bridgeDeployer.deploy(FOUNDRY_BID, address(0x5678));
    }

    function test_should_bridge_deployment_address_be_deterministic_regarding_owner()
        public
    {
        address expectedAddress = _bridgeDeployer.bridgeAddress();

        uint256 signerPk = 0xa11ce;
        address signer = vm.addr(signerPk);
        vm.startPrank(signer);
        address bridgeAddress = _bridgeDeployer.deploy(
            FOUNDRY_BID,
            address(0xb0b)
        );
        vm.stopPrank();

        assertEq(bridgeAddress, expectedAddress);
    }
}
