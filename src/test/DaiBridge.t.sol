// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;

import "ds-test/test.sol";
import "../DaiBridge.sol";
import "./CheatCodes.sol";
import "../Vaults.sol";
import "../Dai.sol";

contract VaultsWithMint is Vaults{
    function giveDai(address to, uint256 amount) public{
        daiBalance[to] += amount;
    }
}
contract DaiBridgeTest is DSTest {
    VaultsWithMint vaults; 
    Dai dai;
    DaiBridge daiBridge; 
    CheatCodes cheats = CheatCodes(HEVM_ADDRESS);

    address self = address(this);

    event Enter(address indexed user, uint256 amount);
    event Exit(address indexed user, uint256 amount);

    function setUp() public {
        vaults = new VaultsWithMint(); 
        dai = new Dai();
        daiBridge = new DaiBridge(address(vaults), address(dai));
    }

    function testEnter() public {

        uint amount =200;
        dai.mint(self, amount);
        dai.approve(address(daiBridge), amount);
        vaults.giveDai(address(daiBridge), amount);

        assertEq(vaults.daiBalance(address(daiBridge)), amount);
        assertEq(vaults.daiBalance(self), 0);

        cheats.expectEmit(true, false, false, true);
        emit Enter(self, amount);
        daiBridge.enter(self , amount);

        assertEq(vaults.daiBalance(address(daiBridge)), 0);
        assertEq(vaults.daiBalance(self), amount);
    }

    function testExit() public {
        uint amount =200;
        vaults.giveDai(address(self), amount);
        vaults.delegate(address(daiBridge));
        dai.authorize(address(daiBridge));
        
        assertEq(vaults.daiBalance(address(daiBridge)), 0);
        assertEq(vaults.daiBalance(self), amount);
        
        cheats.expectEmit(true, false, false, true);
        emit Exit(self, amount);
        daiBridge.exit (self , amount);

        assertEq(vaults.daiBalance(address(daiBridge)), amount);
        assertEq(vaults.daiBalance(self), 0);
    }
}