// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;

import "./Auth.sol";
import "./IVaults.sol";
import "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

//TODO add docs 
abstract contract Bridge is Auth{

    IVaults public vaults;
    bytes32 public tokenId;
    IERC20 public token;

    event Enter(address indexed user, uint256 amount);
    event Exit(address indexed user, uint256 amount);

    constructor(address _vaults, bytes32 _tokenId, address _token) public {
        vaults = IVaults(_vaults);
        tokenId  = _tokenId;
        token = IERC20(_token);
    }

    function enter(address user, uint256 amount) external;
    function exit(address user, uint256 amount) external;
}