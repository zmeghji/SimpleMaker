// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;

import "ds-test/test.sol";
import "../MathLib.sol";

contract MathLibWrapper{
    using MathLib for uint256;

    function addWrapper(uint x, int y) public pure returns (uint z) {
        z=x.add(y);
    }
    function subWrapper(uint x, int y) public pure returns (uint z) {
        z= x.sub(y);
    }
    function mulWrapper(uint x, int y) public pure returns (int z) {
        z= x.mul(y);
    }

}

contract MathLibTest is DSTest {
    MathLibWrapper mathLibWrapper; 

    function setUp() public {
        mathLibWrapper = new MathLibWrapper();
    }

    function testAdd() public {
        assertEq(200,mathLibWrapper.addWrapper(100,100));
    }

    function testAddNegativeNumber() public {
        assertEq(0,mathLibWrapper.addWrapper(100,-100));
    }

    function testSub() public {
        assertEq(50,mathLibWrapper.subWrapper(100,50));
    }

    function testSubNegativeNumber() public {
        assertEq(150,mathLibWrapper.subWrapper(100,-50));
    }

    function testMul() public {
        assertEq(100,mathLibWrapper.mulWrapper(10,10));
    }

    function testMulNegativeNumber() public {
        assertEq(-100,mathLibWrapper.mulWrapper(10,-10));
    }
    //TODO add all overflow/underflow cases
}
