// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;

//TODO document
//TODO test
library MathLib {
    function add(uint x, int y) internal pure returns (uint z) {
        unchecked {
            z = x + uint(y);
            require(y >= 0 || z <= x, "Underflow/Overflow");
            require(y <= 0 || z >= x, "Underflow/Overflow");
        }
    }
    function sub(uint x, int y) internal pure returns (uint z) {
        unchecked {
            z = x - uint(y);
            require(y <= 0 || z <= x, "Underflow/Overflow");
            require(y >= 0 || z >= x, "Underflow/Overflow");
        }
    }
    function mul(uint x, int y) internal pure returns (int z) {
        unchecked {
            z = int(x) * y;
            require(int(x) >= 0, "Underflow/Overflow");
            require(y == 0 || z / y == int(x), "Underflow/Overflow");
        }
    }
}