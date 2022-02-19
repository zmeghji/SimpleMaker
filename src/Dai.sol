// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;

import "./Auth.sol";
import "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import "./IDai.sol";

contract Dai is Auth,ERC20, IDai{

    constructor() ERC20("Simple Dai", "SDAI"){
    }
    /**@dev allows authorized addresses to mint Dai */
    function mint(address to, uint256 amount) external auth {
        _mint(to, amount);
    }
    /**@dev allows burning of dai from an address by an approved address or the address itself */
    function burn(address from, uint256 amount) external virtual {
        if (from != msg.sender){
            _spendAllowance(from, msg.sender, amount);
        }
        _burn(from, amount);
    }
    
}