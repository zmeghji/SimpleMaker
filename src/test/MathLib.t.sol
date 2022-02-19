// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;

import "ds-test/test.sol";
import "../MathLib.sol";
import "./CheatCodes.sol";

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
    CheatCodes cheats = CheatCodes(HEVM_ADDRESS);
    
    uint256 maxUint256;
    // uint256 maxUint128;

    function setUp() public {
        mathLibWrapper = new MathLibWrapper();
        unchecked {
            maxUint256 =(2**256) -1;
        }
        // unchecked {
        //     maxUint128 =(2**128) -1;
        // }
    }

    function testAdd() public {
        assertEq(200,mathLibWrapper.addWrapper(100,100));
    }

    function testAddNegativeNumber() public {
        assertEq(0,mathLibWrapper.addWrapper(100,-100));
    }

    function testAddRevertsOnOverflow() public {
        cheats.expectRevert(bytes("MathLib: add overflow"));
        mathLibWrapper.addWrapper(maxUint256, 1);
    }

    function testAddRevertsOnUnderflow() public {
        cheats.expectRevert(bytes("MathLib: add underflow"));
        mathLibWrapper.addWrapper(0, -1);
    }

    function testSub() public {
        assertEq(50,mathLibWrapper.subWrapper(100,50));
    }

    function testSubNegativeNumber() public {
        assertEq(150,mathLibWrapper.subWrapper(100,-50));
    }

    function testSubRevertsOnOverflow() public {
        cheats.expectRevert(bytes("MathLib: sub overflow"));
        mathLibWrapper.subWrapper(maxUint256, -1);
    }

    function testSubRevertsOnUnderflow() public {
        cheats.expectRevert(bytes("MathLib: sub underflow"));
        mathLibWrapper.subWrapper(0, 1);
    }

    function testMul() public {
        assertEq(100,mathLibWrapper.mulWrapper(10,10));
    }

    function testMulNegativeNumber() public {
        assertEq(-100,mathLibWrapper.mulWrapper(10,-10));
    }
    function testMulRevertsOnOverflowXTooBig() public {
        cheats.expectRevert(bytes("MathLib: mul overflow (x must be less than 2**255)"));
        mathLibWrapper.mulWrapper(2**255, 1);
    }

    function testMulRevertsOnOverflow() public {
        cheats.expectRevert(bytes("MathLib: mul underflow/overflow"));
        mathLibWrapper.mulWrapper(2**255 -1, 2);
    }

    function testMulRevertsOnUnderflow() public {
        cheats.expectRevert(bytes("MathLib: mul underflow/overflow"));
        mathLibWrapper.mulWrapper(2**255 -1, -2);
    }
}
