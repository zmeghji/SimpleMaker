// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;

import "ds-test/test.sol";
import "../Liquidator.sol";
import "./CheatCodes.sol";
import "../Vaults.sol";
import "../Auctioneer.sol";
contract LiquidatorTest is DSTest {
    Liquidator liquidator; 
    CheatCodes cheats = CheatCodes(HEVM_ADDRESS);
    Vaults vaults; 
    Auctioneer tokenAuctioneer;
    Auctioneer otherAuctioneer;
    bytes32 tokenId  ="Token";

    address self = address(this);
    address constant user1 = 0xE0f5206BBD039e7b0592d8918820024e2a7437b9;
    address constant user2 = 0xAb5801a7D398351b8bE11C439e05C5B3259aeC9B;
    
    uint256 originalPrice = 10**27;
    function setUp() public {
        vaults = new Vaults();
        liquidator = new Liquidator(address(vaults));

        tokenAuctioneer = new Auctioneer(address(vaults), tokenId);
        otherAuctioneer = new Auctioneer(address(vaults), "OtherToken");

        vaults.addCollateralType(tokenId);
        vaults.updatePrice(tokenId, originalPrice);

        tokenAuctioneer.authorize(address(liquidator));
    }

    function testUpdatePenalty() public {
        (address auctioneer, uint256 penalty) = liquidator.collateralTypes(tokenId);
        assertEq(penalty, 0);
        uint newValue =10**18;
        liquidator.update(tokenId, "penalty",newValue);
        (auctioneer, penalty) = liquidator.collateralTypes(tokenId);
        assertEq(penalty, newValue);
    }

    function testUpdatePenaltyUnauthorized() public {
        cheats.startPrank(user1);
        cheats.expectRevert(bytes("Auth: msg.sender is not authorized"));
        liquidator.update(tokenId, "penalty",10**18);
    }
    function testUpdatePenaltyLessThanMinimum() public {
        cheats.expectRevert(bytes("Liquidator: penalty must be greater than or equal to 10**18"));
        liquidator.update(tokenId, "penalty",10**17);
    }

    function testUpdateUint256IUnknownField() public {
        cheats.expectRevert(bytes("Liquidator: unrecognized field"));
        liquidator.update(tokenId, "fakeField",10**18);
    }

    function testUpdateAuctioneer() public {
        (address auctioneer, uint256 penalty) = liquidator.collateralTypes(tokenId);
        assertEq(auctioneer, address(0));
        
        liquidator.update(tokenId, "auctioneer",address(tokenAuctioneer));
        (auctioneer, penalty) = liquidator.collateralTypes(tokenId);
        assertEq(auctioneer, address(tokenAuctioneer));
    }

    function testUpdateAuctioneerUnauthorized() public {
        cheats.startPrank(user1);
        cheats.expectRevert(bytes("Auth: msg.sender is not authorized"));
        liquidator.update(tokenId, "auctioneer",address(tokenAuctioneer));

    }

    function testUpdateAuctioneerWrongTokenId() public {
        cheats.expectRevert(bytes("Liquidator: tokenId of auctioneer address provided does not match provided tokenId"));
        liquidator.update(tokenId, "auctioneer",address(otherAuctioneer));
    }

    function testUpdateAddressUnknownField() public {
        cheats.expectRevert(bytes("Liquidator: unrecognized field"));
        liquidator.update(tokenId, "fakeField",address(tokenAuctioneer));
    }

    function testLiquidate() public {
        liquidator.update(tokenId, "auctioneer", address(tokenAuctioneer));
        liquidator.update(tokenId, "penalty", 10**18);
        int256 amount =10;
        vaults.changeTokenBalance(tokenId, self, amount);
        vaults.modifyVault(tokenId, self, self, self, amount, amount);
        (uint256 collateral, uint256 normalizedDebt) = vaults.vaults(tokenId, self);
        assertEq(collateral, uint(amount));
        assertEq(normalizedDebt, uint(amount));
        assertEq(vaults.tokenBalance(tokenId, address(tokenAuctioneer)), 0);
        vaults.updatePrice(tokenId, originalPrice-1);        
        liquidator.liquidate(tokenId, self);

        (collateral, normalizedDebt) = vaults.vaults(tokenId, self);
        assertEq(collateral, 0);
        assertEq(normalizedDebt, 0);
        assertEq(vaults.tokenBalance(tokenId, address(tokenAuctioneer)), uint(amount));
    
    }

    function testLiquidateVaultSafe() public {
        int256 amount =100;
        vaults.changeTokenBalance(tokenId, self, amount);
        vaults.modifyVault(tokenId, self, self, self, amount, amount);

        cheats.expectRevert(bytes("Liquidator: vault is under good standing and not eligible for liquidation"));
        liquidator.liquidate(tokenId, self);
    }

    function testLiquidateNoCollateral() public {
        cheats.expectRevert(bytes("Liquidator: no collateral to auction"));
        liquidator.liquidate(tokenId, self);
    }
    

}