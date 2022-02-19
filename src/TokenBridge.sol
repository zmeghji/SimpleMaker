// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;

import "./Auth.sol";
import "./IVaults.sol";
import "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "./Bridge.sol";

/**@title Adds/removes ERC20 tokens from vaults contract on behalf of user*/
contract TokenBridge is Auth,Bridge{

    constructor(address _vaults, bytes32 _tokenId, address _token)
        Bridge(_vaults, _tokenId, _token){}

    /**@dev Adds ERC20 tokens on behalf of user to vaults contract. Emits Enter event */
    function enter(address user, uint256 amount) override external{
        require(int(amount) >= 0, "amount must be less than 2^255");
        vaults.changeTokenBalance(tokenId, user, int(amount));
        require(
            token.transferFrom(user, address(this), amount),
            "TokenBridge: transferring tokens to bridge failed"
        );
        emit Enter(user, amount);
    }

    /**@dev Removes ERC20 tokens on behalf of user from vaults contract. Emits Exit event */
    function exit(address user, uint256 amount) override external{
        require(int(amount) >= 0, "amount must be less than 2^255");
        vaults.changeTokenBalance(tokenId, user, -int(amount));
        require(
            token.transfer(user, amount),
            "TokenBridge: transferring tokens from bridge to user failed"
        );
        emit Exit(user, amount);
    }
}