// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract MagicNum {
    address public solver;

    constructor() {}

    function setSolver(address _solver) public {
        solver = _solver;
    }

    /*
    ____________/\\\_______/\\\\\\\\\_____        
     __________/\\\\\_____/\\\///////\\\___       
      ________/\\\/\\\____\///______\//\\\__      
       ______/\\\/\/\\\______________/\\\/___     
        ____/\\\/__\/\\\___________/\\\//_____    
         __/\\\\\\\\\\\\\\\\_____/\\\//________   
          _\///////////\\\//____/\\\/___________  
           ___________\/\\\_____/\\\\\\\\\\\\\\\_ 
            ___________\///_____\///////////////__
    */
}

contract MagicNumberDeployer {
    function deploy() external returns (address solver) {
        bytes memory creationCode = hex"600a600c600039600a6000f3602a60005260206000f3";

        assembly {
            solver := create(
                0,
                add(creationCode, 0x20),
                mload(creationCode)
            )
        }

        require(solver != address(0), "Deployment failed");
    }

}

contract Attacker {
    function whatIsTheMeaningOfLife() external pure returns (bytes32) {
        assembly {
            let z:= 0x2a
            mstore(0, z)
            return(0, 0x20)
        }
    }
}