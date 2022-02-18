// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;

import "ds-test/test.sol";
import "../Delegate.sol";
import "./CheatCodes.sol";


contract FakeDelegate is Delegate{}

contract DelegateTest is DSTest {
    FakeDelegate fakeDelegate; 
    CheatCodes cheats = CheatCodes(HEVM_ADDRESS);

    address constant user1 = 0xE0f5206BBD039e7b0592d8918820024e2a7437b9;
    address constant user2 = 0xAb5801a7D398351b8bE11C439e05C5B3259aeC9B;

    address self = address(this);

    function setUp() public {
        fakeDelegate = new FakeDelegate();
    }

    function testDelegate() public {
        assertTrue(!fakeDelegate.isDelegate(user1, user2));

        cheats.prank(user1);
        fakeDelegate.delegate(user2);

        assertTrue(fakeDelegate.isDelegate(user1, user2));
    }

    function testUndelegate() public {
        cheats.startPrank(user1);
        fakeDelegate.delegate(user2);
        assertTrue(fakeDelegate.isDelegate(user1, user2));

        fakeDelegate.undelegate(user2);

        assertTrue(!fakeDelegate.isDelegate(user1, user2));
    }

    function testIsDelegateOnSelf() public{
        assertTrue(fakeDelegate.isDelegate(self, self));
    }

}
