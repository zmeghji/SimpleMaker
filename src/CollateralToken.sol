// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";


/**@title contract for test tokens to connect to Maker Protocol*/
/**@dev has hard-coded initial supply of 1000 paid out to deployer, with a faucet method for minting 10 tokens at a time */
contract CollateralToken  is ERC20 {
    constructor(string memory name_, string memory symbol_) 
        ERC20(name_, symbol_) {
        _mint(msg.sender, 1000 * 10 ** decimals());
    }

    /**@dev mint 10 tokens and send them to caller */
    function faucet() external{
        _mint(msg.sender, 10);
    }

    /**@dev mint a maximum of 100 tokens and send them to caller */
    function faucet(uint256 amount) external{
        require(amount <= 100);
        _mint(msg.sender, amount);
    }
}