// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;

import "./Auth.sol";
import "./IVaults.sol";
import "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

/**@title Base contract for adding/removing assets from vaults contract*/
abstract contract Bridge is Auth{

    IVaults public vaults;
    bytes32 public tokenId;
    IERC20 public token;

    /**@dev Emmitted when assets are added by user to vaults contract */
    event Enter(address indexed user, uint256 amount);
    /**@dev Emmitted when assets are removed by user from vaults contract */
    event Exit(address indexed user, uint256 amount);

    constructor(address _vaults, bytes32 _tokenId, address _token) {
        vaults = IVaults(_vaults);
        tokenId  = _tokenId;
        token = IERC20(_token);
    }
    
    /**@dev Adds assets on behalf of user to vaults contract. Emits Enter event */
    function enter(address user, uint256 amount) virtual external;

    /**@dev Removes assets on behalf of user from vaults contract. Emits Exit event */
    function exit(address user, uint256 amount) virtual external;
}