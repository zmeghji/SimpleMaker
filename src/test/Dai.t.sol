// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;

import "ds-test/test.sol";
import "../Dai.sol";
import "./CheatCodes.sol";

contract DaiTest is DSTest {
    Dai dai; 
    address constant user = 0xE0f5206BBD039e7b0592d8918820024e2a7437b9;
    CheatCodes cheats = CheatCodes(HEVM_ADDRESS);
    address self = address(this);

    function setUp() public {
        dai = new Dai();
    }

    // mint tests
    function testDeployerMint() public {
        assertEq(0,dai.balanceOf(user));
        uint amount =100;
        dai.mint(user, amount);
        assertEq(amount,dai.balanceOf(user));
    }

    function testAuthorizedUserMint() public{
        assertEq(0,dai.balanceOf(user));
        uint amount =100;
        dai.authorize(user);
        cheats.prank(user);
        dai.mint(user, amount);
        assertEq(amount,dai.balanceOf(user));
    }

    function testUnauthorizedUserMint() public{
        cheats.prank(user);
        cheats.expectRevert(bytes("Auth: msg.sender is not authorized"));
        dai.mint(user, 100);
    }

    // burn tests
    function testBurnFromSelf() public{
        uint amount =100;
        dai.mint(self, amount);
        assertEq(amount,dai.balanceOf(self));

        dai.burn(self, amount);
        assertEq(0,dai.balanceOf(self));
    }

    function testBurnByApprovedUser() public {
        uint amount =100;
        dai.mint(self, amount);
        assertEq(amount,dai.balanceOf(self));
        dai.approve(user, amount);

        cheats.prank(user);
        dai.burn(self, amount);
        assertEq(0,dai.balanceOf(self));
    }

    function testBurnByUnapprovedUser() public {
        uint amount =100;
        dai.mint(self, amount);
        assertEq(amount,dai.balanceOf(self));

        cheats.prank(user);
        cheats.expectRevert(bytes("ERC20: insufficient allowance"));
        dai.burn(self, amount);
    }
}
