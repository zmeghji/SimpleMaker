// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;

//TODO add docs on contract level
abstract contract Delegate{

    /**@dev
        delegator => (delegatee => approved(0 or 1))
        Represents which users can act on behalf of others */
    mapping(address => mapping (address => uint)) public delegates;

    /**@dev adds delegate for user */
    function delegate (address delegatee) external{
        delegates[msg.sender][delegatee] = 1;
    }

    /**@dev removes delegate for user */
    function undelegate (address delegatee) external{
        delegates[msg.sender][delegatee] = 0;
    }

    /**@dev
        Checks whether user is a delegate of another user
        Returns true if the same user is passed for both parameters */
    function isDelegate(address delegator, address delegatee) public view returns(bool) {
        return 
            delegator == delegatee || 
            delegates[delegator][delegatee] ==1;
    }

}