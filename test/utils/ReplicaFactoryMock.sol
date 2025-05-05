// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {ReplicaFactory, IBridge} from "../../src/assets/ReplicaFactory.sol";

contract ReplicaFactoryMock is ReplicaFactory {
    constructor(IBridge bridge) ReplicaFactory(bridge) {}
}
