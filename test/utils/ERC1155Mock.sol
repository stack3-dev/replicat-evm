// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {ERC1155} from "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";

contract ERC1155Mock is ERC1155 {
    constructor(string memory tokenURI) ERC1155(tokenURI) {}

    function mint(address account, uint256 tokenId, uint256 amount, bytes memory data) external {
        _mint(account, tokenId, amount, data);
    }
}
