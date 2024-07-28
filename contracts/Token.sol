// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Token is ERC20, Ownable {
  constructor(
    string memory _tokenName,
    string memory _tokenSymbol,
    uint256 _initialSupply
  ) ERC20(_tokenName, _tokenSymbol) {
    _mint(msg.sender, _initialSupply * (1e18));
  }
}
