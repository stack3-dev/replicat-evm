// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {Test, console} from "forge-std/Test.sol";
import {IBridge, Bridge, Ownable} from "../../src/bridge/Bridge.sol";
import {WormholeRelayerMock} from "../utils/WormholeRelayerMock.sol";
import {MessageTransfer, LibMessageTransfer} from "../../src/types/MessageTransfer.sol";
import {ETHEREUM_BID} from "../../src/utils/BridgeChains.sol";
import {FOUNDRY_BID} from "../../src/utils/BridgeChains.sol";

abstract contract BridgeBaseTest is Test {
    Bridge public _bridge;
    WormholeRelayerMock public _wormholeRelayerMock;

    function setUp() public {
        _wormholeRelayerMock = new WormholeRelayerMock();
        _bridge = new Bridge(address(this), FOUNDRY_BID, address(_wormholeRelayerMock));

        _setUp();
    }

    function _setUp() internal virtual {}

    function _mockReceive(MessageTransfer memory message) internal {
        _wormholeRelayerMock.mockReceive(_bridge, message.encode(), address(_bridge), ETHEREUM_BID);
    }
}
