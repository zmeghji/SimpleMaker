// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;

import "ds-test/test.sol";
import "../Auth.sol";

interface CheatCodes {
  function prank(address) external;
  function expectRevert(bytes calldata) external;
}

contract FakeAuth is Auth{
    function restricted() auth public returns (uint256){
        return 100;
    }

    function open() public returns (uint256){
        return 200;
    }
}

contract AuthTest is DSTest {
    FakeAuth fakeAuth; 
    CheatCodes cheats = CheatCodes(HEVM_ADDRESS);

    function setUp() public {
        fakeAuth = new FakeAuth();
    }

    function testDeployerAccessRestricted() public {
        assertEq(100, fakeAuth.restricted());
    }

    function testDeployerAccessOpen() public {
        assertEq(200, fakeAuth.open());
    }

    function testUnauthorizedAccessRestricted() public{
        cheats.expectRevert(
            bytes("Auth: msg.sender is not authorized")
        );
        cheats.prank(address(0));
        fakeAuth.restricted();
    }

    function testUnauthorizedAccessOpen() public{
        cheats.prank(address(0));
        assertEq(200, fakeAuth.open());
    }

    function testAuthorize() public{
        fakeAuth.authorize(address(0));
        cheats.prank(address(0));
        assertEq(100, fakeAuth.restricted());
    }

    function testUnauthorize() public{
        fakeAuth.unauthorize(address(this));
        cheats.expectRevert(
            bytes("Auth: msg.sender is not authorized")
        );
        fakeAuth.restricted();
    }
}
