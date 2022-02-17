// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;

abstract contract Auth{

    /** @dev 
        A mapping of authorized addresses. These addresses will be able to execute functions marked with the auth modifier.
        If  the value for the address is 1, then the address is authorized, otherwise it is not authorized
    */
    mapping (address => uint) public authorized;

    /**@dev constructor sets deployer as an authorized user */
    constructor(){
        authorized[msg.sender]=1;
    }

    /** @dev Method for adding an authorized address*/
    function authorize(address _address) external auth { 
        authorized[_address] = 1; 
    }

    /** @dev Method for removing an authorized address*/
    function unauthorize(address _address) external auth { 
        authorized[_address] = 0; 
    }

    /** @dev Modifier to be used with method which require an authorized address to call them*/
    modifier auth {
        require(authorized[msg.sender] == 1, "Auth: msg.sender is not authorized");
        _;
    }
}