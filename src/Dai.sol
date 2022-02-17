// // SPDX-License-Identifier: UNLICENSED
// pragma solidity 0.8.10;

// import "./Auth.sol";

// //TODO import openzeppelin
// contract Dai is Auth,ERC20{

//     constructor() ERC20("Simple Dai", "SDAI"){
//     }

//     function mint(address to, uint256 amount) public auth {
//         _mint(to, amount);
//     }
//     function burn(address from, uint256 amount) public virtual {
//         _spendAllowance(from, msg.sender, amount);
//         _burn(from, amount);
//     }
    
// }