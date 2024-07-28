// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract Owned {
  address public owner;
  address private pendingOwner;

  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );

  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );
}
