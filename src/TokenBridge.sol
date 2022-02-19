// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;

import "./Auth.sol";
import "./IVaults.sol";
import "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "./Bridge.sol";

//TODO add docs 
//TODO add tests
contract TokenBridge is Auth,Bridge{

    constructor(address _vaults, bytes32 _tokenId, address _token) public
        Bridge(_vaults, _tokenId, _token){}


    function enter(address user, uint256 amount) external{

        require(int(amount) >= 0, "amount must be less than 2^128");
        vaults.changeTokenBalance(tokenId, user, int(amount));
        //TODO complete
    }

    function exit(address user, uint256 amount) external{

    }
}