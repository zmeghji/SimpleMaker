// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;

/** @title Library for math helper functions 
    @dev 
        Some of these methods actually use overflows for arithmetic such as adding a negative int to a uint.
        However unintended overflows/underflows will still cause a revert
*/

library MathLib {
    /**@dev adds an uint to an int, reverts on unintended overflow/underflow */
    function add(uint x, int y) internal pure returns (uint z) {
        unchecked {
            z = x + uint(y);
            require(y >= 0 || z <= x, "MathLib: add underflow");
            require(y <= 0 || z >= x, "MathLib: add overflow");
        }
    }
    /**@dev subtracts an int from a uint, reverts on unintended overflow/underflow */
    function sub(uint x, int y) internal pure returns (uint z) {
        unchecked {
            z = x - uint(y);
            require(y <= 0 || z <= x, "MathLib: sub underflow");
            require(y >= 0 || z >= x, "MathLib: sub overflow");
        }
    }

    /**@dev multiplies a uint by an int, reverts on unintended overflow/underflow */
    function mul(uint x, int y) internal pure returns (int z) {
        unchecked {
            z = int(x) * y;
            require(int(x) >= 0, "MathLib: mul overflow (x must be less than 2**255)");
            require(y == 0 || z / y == int(x), "MathLib: mul underflow/overflow");
        }
    }

    function min(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x <= y ? x : y;
    }
}