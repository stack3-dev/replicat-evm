# replicaT

**replicaT** is a canonical token bridge enabling seamless and permissionless token replication across EVM-compatible blockchains. It supports both fungible (ERC20) and non-fungible (ERC721) tokens, ensuring interoperability and efficient cross-chain functionality for decentralized applications. 
## Wormhole Cross-Chain Messaging

**replicaT** leverages Wormhole's cross-chain messaging protocol to facilitate secure and efficient communication between EVM-compatible blockchains. This integration ensures that token replication and transfers are executed seamlessly, maintaining the integrity and utility of the tokens across different chains.

## Superchain Bridge Compatibility

**replicaT** tokens are fully compatible with the Superchain bridge, enabling seamless and cost-efficient token transfers within the Superchain ecosystem. This compatibility ensures that fungible (ERC20) tokens replicated through **replicaT** can leverage the Superchain's ecosystem for faster and cheaper cross-chain transactions. This integration enhances the overall interoperability and scalability of decentralized applications operating across EVM-compatible blockchains.

## Use cases

### Non-upgradeable tokens

**replicaT** supports the replication of non-upgradeable tokens, ensuring that token contracts remain immutable and secure. This feature is particularly beneficial for projects that prioritize decentralization and trust minimization. By replicating non-upgradeable tokens, developers can maintain the integrity of their token contracts while enabling cross-chain functionality.

### Bridge Superchain ERC20 to other EVM chains

With **replicaT**, ERC20 tokens within the Superchain ecosystem can be seamlessly bridged to other EVM-compatible blockchains. This functionality allows token holders to transfer assets across chains without compromising on speed or cost-efficiency. The bridge ensures that tokens retain their original properties and utility, enabling interoperability and expanding the reach of decentralized applications across multiple blockchain networks.

## Foundry

## Documentation

https://book.getfoundry.sh/

## Usage

### Build

```shell
$ forge build
```

### Test

```shell
$ forge test
```

### Format

```shell
$ forge fmt
```

### Gas Snapshots

```shell
$ forge snapshot
```

### Anvil

```shell
$ anvil
```

## Deployment

### Deploy bridge

```shell
$ forge script script/Bridge.s.sol:BridgeScript --sig "deploy(address, uint16, address)" $DEPLOYER CHAINID WORMHOLERELAYER ...
```

# create ERC20 replica
```shell
$ forge script script/Bridge.s.sol:BridgeScript --sig "createReplicaERC20(address,uint256,address,string,string,uint8)" 0xf303343F427157A306E4931f396b448fc6F357dE 11155111 0x779877A7B0D9E8603169DdbD7836e478b4624789 "ChainLink Token" LINK 18 ...
```

# create ERC20 adapter
```shell
$ forge script script/Bridge.s.sol:BridgeScript --sig "createReplicaERC20Adapter(address,uint256,address,string,string,uint8)" 0xf303343F427157A306E4931f396b448fc6F357dE 11155111 0x779877A7B0D9E8603169DdbD7836e478b4624789 "ChainLink Token" LINK 18 ...
```

# send ERC20 
```shell
$ forge script script/Bridge.s.sol:BridgeScript --sig "sendERC20(address,uint256,address,uint256,address,uint256,address,uint256,uint256,uint256)" 0xf303343F427157A306E4931f396b448fc6F357dE 11155111 0x779877A7B0D9E8603169DdbD7836e478b4624789 11155111 $DEPLOYER 11155420 $DEPLOYER 10000000000000000000 1 100000000000000 ....
```

# Extra params exemple

```shell
... --sender $DEPLOYER --private-key $DEPLOYER_PK --rpc-url $SEPOLIA_RPC_URL --verify --verifier-url $SEPOLIA_ETHERSCAN_URL --etherscan-api-key $ETHERSCAN_API_KEY -vvvv --broadcast

... --sender $DEPLOYER --private-key $DEPLOYER_PK --rpc-url $OP_SEPOLIA_RPC_URL --verify --verifier-url $OP_SEPOLIA_ETHERSCAN_URL --etherscan-api-key $OP_ETHERSCAN_API_KEY -vvvv --broadcast 

... --sender $DEPLOYER --private-key $DEPLOYER_PK --rpc-url $BASE_SEPOLIA_RPC_URL --verify --verifier-url $BASE_SEPOLIA_BASESCAN_URL --etherscan-api-key $BASESCAN_API_KEY -vvvv --broadcast 
```

### Cast

```shell
$ cast <subcommand>
```

### Help

```shell
$ forge --help
$ anvil --help
$ cast --help
```


