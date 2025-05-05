#!/bin/bash
set -e

DEPLOYER_ADDRESS=0xcA379F93332bAFe1ec1B1bFa7D01E459dc204C25
WH_CHAINID=1
WH_RELAYER_ADDRESS=0xXX

# deploy bridge
forge script script/Bridge.s.sol:BridgeScript --sig "deploy(address,uint16,address)" $DEPLOYER_ADDRESS $WH_CHAINID $WH_RELAYER_ADDRESS $@
