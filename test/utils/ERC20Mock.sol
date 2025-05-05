// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {ERC20Permit} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";

contract ERC20Mock is ERC20, ERC20Permit {
    constructor(string memory name, string memory symbol) ERC20(name, symbol) ERC20Permit(name) {}

    function mint(address account, uint256 amount) external {
        _mint(account, amount);
    }

    /// @dev Compute the hash of a data structure following EIP-712 spec.
    /// @param structHash the structHash(message) to hash
    function hash(bytes32 structHash) public view returns (bytes32) {
        return _hash(structHash);
    }

    /// @dev Compute the hash of a data structure following EIP-712 spec.
    /// @param dataHash_ the structHash(message) to hash
    function _hash(bytes32 dataHash_) private view returns (bytes32) {
        return _hashTypedDataV4(dataHash_);
    }
}
