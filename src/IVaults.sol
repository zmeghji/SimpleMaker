// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;

interface IVaults {
    /**@dev 
        changes the token balance of a user by the specified amount. 
        Can only be called by authorized addresses */
    function changeTokenBalance(bytes32 tokenId, address user, int256 amount) external;    


    /**@dev 
        moves specified amount of  dai between source and destination
        msg.sender must be a delegate of the source address  */
    function moveDai(address src, address dst, uint256 amount) external;
}