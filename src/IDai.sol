// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;

import "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

interface IDai is IERC20{

    /**@dev allows authorized addresses to mint Dai */
    function mint(address to, uint256 amount) external;

    /**@dev allows burning of dai from an address by an approved address or the address itself */
    function burn(address from, uint256 amount) external;
}