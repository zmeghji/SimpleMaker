// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;

import "ds-test/test.sol";
import "../Vaults.sol";
import "./CheatCodes.sol";


contract VaultsWithMint is Vaults{
    function giveDai(address to, uint256 amount) public{
        daiBalance[to] += amount;
    }
}

contract VaultsTest is DSTest {
    VaultsWithMint vaults; 
    CheatCodes cheats = CheatCodes(HEVM_ADDRESS);

    bytes32 tokenId = "MKR";

    function setUp() public {
        vaults = new VaultsWithMint();
    }

    address constant user1 = 0xE0f5206BBD039e7b0592d8918820024e2a7437b9;
    address constant user2 = 0xAb5801a7D398351b8bE11C439e05C5B3259aeC9B;

    function testAddCollateralType() public {
        (,uint256 rate,) =vaults.collateralTypes(tokenId);
        assertEq(rate, 0);
        vaults.addCollateralType(tokenId);
        (,rate,) =vaults.collateralTypes(tokenId);
        assertEq(rate, 10**27 );
    }

    function testAddCollateralTypeTwice() public {
        vaults.addCollateralType(tokenId);
        cheats.expectRevert(bytes("Vault: collateral type with tokenId already added"));
        vaults.addCollateralType(tokenId);
    }

    function testAddCollateralTypeUnauthorized() public{
        cheats.startPrank(user1);
        cheats.expectRevert(bytes("Auth: msg.sender is not authorized"));
        vaults.addCollateralType(tokenId);
    }

    function testUpdatePrice() public{
        vaults.addCollateralType(tokenId);
        (,,uint256 price) =vaults.collateralTypes(tokenId);
        assertEq(price, 0);

        uint newPrice = 100;
        vaults.updatePrice(tokenId, newPrice);
        (,,price) =vaults.collateralTypes(tokenId);
        assertEq(price, newPrice);

    }
    function testUpdatePriceUnauthorized() public{
        vaults.addCollateralType(tokenId);
        cheats.startPrank(user1);
        cheats.expectRevert(bytes("Auth: msg.sender is not authorized"));
        vaults.updatePrice(tokenId, 100);
    }

    function testChangeTokenBalance() public {
        vaults.addCollateralType(tokenId);
        assertEq(vaults.tokenBalance(tokenId, user1),0);

        int256 newBalance =100;
        vaults.changeTokenBalance(tokenId, user1, newBalance);        
        assertEq(vaults.tokenBalance(tokenId, user1),uint256(newBalance));
    }

    function testChangeTokenBalanceUnderflow() public {
        vaults.addCollateralType(tokenId);
        assertEq(vaults.tokenBalance(tokenId, user1),0);
        int256 newBalance =-100;

        cheats.expectRevert(bytes("Underflow/Overflow"));
        vaults.changeTokenBalance(tokenId, user1, newBalance);        
    }

    function testChangeTokenBalanceUnauthorized() public{
        vaults.addCollateralType(tokenId);
        cheats.startPrank(user1);
        cheats.expectRevert(bytes("Auth: msg.sender is not authorized"));
        vaults.changeTokenBalance(tokenId, user1, 100);
    }

    function testMoveTokens() public {
        vaults.addCollateralType(tokenId);
        int256 newBalance =100;
        vaults.changeTokenBalance(tokenId, user1, newBalance);        
        assertEq(vaults.tokenBalance(tokenId, user1),uint256(newBalance));
        assertEq(vaults.tokenBalance(tokenId, user2),0);

        cheats.prank(user1);
        vaults.moveTokens(tokenId, user1, user2, uint256(newBalance));

        assertEq(vaults.tokenBalance(tokenId, user1),0);
        assertEq(vaults.tokenBalance(tokenId, user2),uint256(newBalance));
    }

    function testFailMoveTokensNotEnoughToMove() public {
        vaults.addCollateralType(tokenId);
        int256 newBalance =100;
        vaults.changeTokenBalance(tokenId, user1, newBalance);        
        assertEq(vaults.tokenBalance(tokenId, user1),uint256(newBalance));
        assertEq(vaults.tokenBalance(tokenId, user2),0);

        cheats.startPrank(user1);
        vaults.moveTokens(tokenId, user1, user2, uint256(newBalance+1));
    }

    function testMoveTokensNotDelegate() public {
        vaults.addCollateralType(tokenId);
        int256 newBalance =100;
        vaults.changeTokenBalance(tokenId, user1, newBalance);        

        cheats.expectRevert(bytes("Vaults: msg.sender is not a delegate of src address"));
        vaults.moveTokens(tokenId, user1, user2, uint256(newBalance));

    }


    function testMoveDai() public {
        uint256 amount = 100;
        vaults.giveDai(user1, amount);
        assertEq(vaults.daiBalance(user1), amount);
        assertEq(vaults.daiBalance(user2), 0);

        cheats.prank(user1);
        vaults.moveDai(user1, user2, amount);

        assertEq(vaults.daiBalance(user1), 0);
        assertEq(vaults.daiBalance(user2), amount);
    }
}