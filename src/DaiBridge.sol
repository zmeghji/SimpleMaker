// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;

import "./Auth.sol";
import "./Bridge.sol";
import "./IDai.sol";

/**@title Adds/removes Dai from vaults contract on behalf of user*/
contract DaiBridge is Auth,Bridge {

    IDai dai;
    constructor(address _vaults, address _dai)
        Bridge(_vaults)
    {
        dai = IDai(_dai);
    }

    /**@dev Adds Dai on behalf of user to vaults contract. Emits Enter event */
    function enter(address user, uint256 amount) override external{
        vaults.moveDai(address(this), user, amount*10**27);
        dai.burn(user, amount);
        emit Enter(user, amount);
    }

    /**@dev Removes Dai on behalf of user from vaults contract. Emits Exit event */
    function exit(address user, uint256 amount) override external{
        vaults.moveDai(user, address(this), amount*10**27);
        dai.mint(user, amount);
        emit Exit(user, amount);
    }

}