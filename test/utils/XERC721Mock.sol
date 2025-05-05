// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {ERC721, IERC165} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {ERC721Burnable} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import {CREATE3} from "../../src/vendors/CREATE3.sol";
import {Asset, AssetType} from "../../src/types/Asset.sol";
import {MetadataNFT} from "../../src/types/MetadataNFT.sol";
import {IXNFT} from "../../src/assets/interfaces/IXNFT.sol";

contract XERC721Mock is IXNFT, ERC721, ERC721Burnable {
    address private _bridge;

    modifier onlyBridge() {
        require(msg.sender == _replicaAdapterAddress(), "XERC721Mock: caller is not the bridge replica adapter");
        _;
    }

    constructor(string memory name, string memory symbol, address bridge) ERC721(name, symbol) {
        _bridge = bridge;
    }

    function mint(address account, uint256 amount) external {
        _mint(account, amount);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, IERC165) returns (bool) {
        return interfaceId == type(IXNFT).interfaceId || super.supportsInterface(interfaceId);
    }

    /// @inheritdoc IXNFT
    function crosschainBurn(address from, uint256 tokenId) external override onlyBridge {
        // verify the token owner
        require(_ownerOf(tokenId) == from, "XERC721Mock: invalid token owner");

        _burn(tokenId);

        emit CrosschainBurn(from, tokenId, msg.sender);
    }

    /// @inheritdoc IXNFT
    function crosschainMint(address to, uint256 tokenId) external override onlyBridge {
        _safeMint(to, tokenId);

        emit CrosschainMint(to, tokenId, msg.sender);
    }

    function _replicaAdapterAddress() internal view returns (address) {
        bytes32 salt = asset().hash();
        return CREATE3.predictDeterministicAddress(salt, _bridge);
    }

    function asset() public view returns (Asset memory) {
        return Asset({
            type_: AssetType.XNFT,
            chainBid: 0,
            address_: address(this),
            metadata: MetadataNFT(name(), symbol()).encode()
        });
    }
}
