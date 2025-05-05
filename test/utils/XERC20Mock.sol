// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {ERC20, IERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {ERC20Permit} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import {IERC7802} from "@interop-lib/interfaces/IERC7802.sol";
import {CREATE3} from "../../src/vendors/CREATE3.sol";
import {Asset, AssetType} from "../../src/types/Asset.sol";
import {MetadataFT} from "../../src/types/MetadataFT.sol";

contract XERC20Mock is ERC20, IERC7802 {
    address private _bridge;

    modifier onlyBridge() {
        require(msg.sender == _replicaAdapterAddress(), "XERC20Mock: caller is not the bridge replica adapter");
        _;
    }

    constructor(string memory name, string memory symbol, address bridge) ERC20(name, symbol) {
        _bridge = bridge;
    }

    function mint(address account, uint256 amount) external {
        _mint(account, amount);
    }

    function supportsInterface(bytes4 interfaceId) external pure override returns (bool) {
        return interfaceId == type(IERC7802).interfaceId || interfaceId == type(IERC20).interfaceId;
    }

    function crosschainMint(address _to, uint256 _amount) external override onlyBridge {
        _mint(_to, _amount);
    }

    function crosschainBurn(address _from, uint256 _amount) external override onlyBridge {
        _burn(_from, _amount);
    }

    function _replicaAdapterAddress() internal view returns (address) {
        bytes32 salt = asset().hash();
        return CREATE3.predictDeterministicAddress(salt, _bridge);
    }

    function asset() public view returns (Asset memory) {
        return Asset({
            type_: AssetType.XFT,
            chainBid: 0,
            address_: address(this),
            metadata: MetadataFT(name(), symbol(), decimals()).encode()
        });
    }
}
