// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;


//TODO add docs on contract level
abstract contract Auth{

    /** @dev 
        A mapping of authorized addresses. These addresses will be able to execute functions marked with the auth modifier.
        If  the value for the address is 1, then the address is authorized, otherwise it is not authorized
    */
    mapping (address => uint) public authorized;
    
    event Authorize(address indexed user);
    event Unauthorize(address indexed user);


    /**@dev constructor sets deployer as an authorized user */
    constructor(){
        authorized[msg.sender]=1;
        emit Authorize(msg.sender);
    }

    /** @dev Method for adding an authorized address*/
    function authorize(address user) external auth { 
        authorized[user] = 1; 
        emit Authorize(user);
    }

    /** @dev Method for removing an authorized address*/
    function unauthorize(address user) external auth { 
        authorized[user] = 0; 
        emit Unauthorize(user);
    }

    /** @dev Modifier to be used with method which require an authorized address to call them*/
    modifier auth {
        require(authorized[msg.sender] == 1, "Auth: msg.sender is not authorized");
        _;
    }
}