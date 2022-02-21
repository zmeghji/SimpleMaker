// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;

import "ds-test/test.sol";
import "../Auctioneer.sol";
import "./CheatCodes.sol";
import "../Vaults.sol";


contract VaultsWithMint is Vaults{
    function giveDai(address to, uint256 amount) public{
        daiBalance[to] += amount;
    }
}
contract AuctioneerTest is DSTest {
    Auctioneer auctioneer; 
    CheatCodes cheats = CheatCodes(HEVM_ADDRESS);

    address self = address(this);
    address constant user1 = 0xE0f5206BBD039e7b0592d8918820024e2a7437b9;
    address constant user2 = 0xAb5801a7D398351b8bE11C439e05C5B3259aeC9B;
    VaultsWithMint vaults;
    bytes32 tokenId = "Token";
    
    event StartAuction (
        uint256 indexed id,
        uint256 startAmount,
        uint256 debt,
        uint256 collateral,
        address indexed vaultOwner
    );
    event Buy(
        uint256 indexed auctionid,
        uint256 maxPrice,
        uint256 price,
        uint256 daiPaid,
        uint256 remainingDebt,
        uint256 remainingCollateral,
        address indexed vaultOwner
    );
    event RestartAuction(
        uint256 indexed id,
        uint256 startPrice,
        uint256 debt,
        uint256 collateral,
        address indexed vaultOwner
    );
    function setUp() public {
        vaults = new VaultsWithMint();
        auctioneer = new Auctioneer(address(vaults), tokenId);

        vaults.delegate(address(auctioneer));
    }

    function testStartAuction() public {
        uint256 priceMultiplier = 10**27;
        auctioneer.update("priceMultiplier", priceMultiplier);

        uint price = 10**27;
        vaults.updatePrice(tokenId, price);
        uint amount = 200;
        uint256 nextTokenId = auctioneer.nextAuctionId();


        cheats.expectEmit(true, false, false, true);
        emit StartAuction(nextTokenId, price, amount, amount, self);
        uint auctionId = auctioneer.startAuction(amount, amount, self);

        (uint256 activeIndex, uint256 debt, uint256 collateral,
            address vaultOwner, uint96 startTime, uint256 startPrice) =auctioneer.auctions(auctionId);

        assertEq(collateral, amount );
        assertEq(debt, amount );
        assertEq(vaultOwner, self);
        assertEq(startTime, uint96(block.timestamp));
        assertEq(startPrice, price );
    }

    function testStartAuctionNoDebt() public {
        cheats.expectRevert(bytes("Auctioneer: debt is 0, nothing to auction"));
        auctioneer.startAuction(0, 200, self);
    }
    function testStartAuctionNoCollateral() public {
        cheats.expectRevert(bytes("Auctioneer: collateral is 0, nothing to auction"));
        auctioneer.startAuction(200, 0, self);
    }
    function testStartAuctionUnauthorized() public {
        cheats.startPrank(user1);
        cheats.expectRevert(bytes("Auth: msg.sender is not authorized"));
        auctioneer.startAuction(200, 200, self);
    }

    function testBuy() public {
        uint price = 10**27;
        uint amount = 200;

        vaults.updatePrice(tokenId, price);
        vaults.changeTokenBalance(tokenId, address(auctioneer), int(amount));
        vaults.giveDai(self, amount*price);
        uint256 priceMultiplier = 10**27;
        auctioneer.update("priceMultiplier", priceMultiplier);
        auctioneer.update("tau", 60);

        

        vaults.updatePrice(tokenId, price);
        uint auctionId = auctioneer.startAuction(amount*price, amount, self);

        assertEq(vaults.tokenBalance(tokenId , self), 0);
        assertEq(vaults.daiBalance(self), price*amount);
        assertEq(vaults.tokenBalance(tokenId,address(auctioneer)), amount);

        cheats.expectEmit(true, false, false, true);
        emit Buy(auctionId, price, price, price*amount, 0, 0, self);
        auctioneer.buy(auctionId, amount, price, self);

        assertEq(vaults.tokenBalance(tokenId,self), amount);
        assertEq(vaults.daiBalance(self), 0);
        assertEq(vaults.tokenBalance(tokenId,address(auctioneer)), 0);

        (uint256 activeIndex, uint256 debt, uint256 collateral,
            address vaultOwner, uint96 startTime, uint256 startPrice) =auctioneer.auctions(auctionId);
        assertEq(vaultOwner, address(0));

    }

    function testBuyAuctionNotStarted() public {
        cheats.expectRevert("Auctioneer: action has not been started");
        auctioneer.buy(0, 200, 10**27, self);
    }

    function testBuyAuctionNeedsToBeReset() public {
        uint price = 10**27;
        uint amount = 200;

        vaults.updatePrice(tokenId, price);
        vaults.changeTokenBalance(tokenId, address(auctioneer), int(amount));
        vaults.giveDai(self, amount*price);
        uint256 priceMultiplier = 10**27;
        auctioneer.update("priceMultiplier", priceMultiplier);
        auctioneer.update("tau", 60);
        auctioneer.update("maxDuration", 60);

        vaults.updatePrice(tokenId, price);
        uint auctionId = auctioneer.startAuction(amount*price, amount, self);
        cheats.warp(block.timestamp+61*1000);

        cheats.expectRevert(bytes("Auctioneer: auction has to be reset. Either the minimum price or maximum duration was reached."));
        auctioneer.buy(auctionId, amount, price, self);

    }

    function testBuyCurrentPriceExceedsRequestedPrice() public {
        uint price = 10**27;
        uint amount = 200;

        vaults.updatePrice(tokenId, price);
        vaults.changeTokenBalance(tokenId, address(auctioneer), int(amount));
        vaults.giveDai(self, amount*price);
        uint256 priceMultiplier = 10**27;
        auctioneer.update("priceMultiplier", priceMultiplier);
        auctioneer.update("tau", 60);
        auctioneer.update("maxDuration", 60);

        vaults.updatePrice(tokenId, price+1);
        uint auctionId = auctioneer.startAuction(amount*price, amount, self);

        cheats.expectRevert(bytes("Auctioneer: Current price exceeds requested maximum price"));
        auctioneer.buy(auctionId, amount, price, self);

    }
    
    function testBuyTwoBuyersCollateralLeft() public {
        /** Scenario:
            An auction is started for 100 tokens with debt =100* 10**27
            User 1 buys 35 tokens @ 2*10**27 per token
            User 2 buys 15 tokens @ 2*10**27 per token 
            Auction ends and 50 tokens sent back to vault owner self*/

        uint price = 10**27;

        vaults.updatePrice(tokenId, price);
        vaults.changeTokenBalance(tokenId, address(auctioneer), 100);

        vaults.giveDai(user1, 35*2*10**27 );
        vaults.giveDai(user2, 15*2*10**27 );

        uint256 priceMultiplier = 2*10**27;
        auctioneer.update("priceMultiplier", priceMultiplier);
        auctioneer.update("tau", 60);

        vaults.updatePrice(tokenId, price);
        uint auctionId = auctioneer.startAuction(100*price, 100, self);

        cheats.startPrank(user1);
        vaults.delegate(address(auctioneer));
        auctioneer.buy(auctionId, 35, 2*10**27, user1);
        assertEq(vaults.tokenBalance(tokenId,user1), 35);
        cheats.stopPrank();

        cheats.startPrank(user2);
        vaults.delegate(address(auctioneer));
        auctioneer.buy(auctionId, 15, 2*10**27, user2);
        assertEq(vaults.tokenBalance(tokenId,user2), 15);
        cheats.stopPrank();

        assertEq(vaults.tokenBalance(tokenId,self), 50);
    }
     
    
    function testRestartAuction() public {
         uint price = 10**27;
        uint amount = 200;

        vaults.updatePrice(tokenId, price);
        vaults.changeTokenBalance(tokenId, address(auctioneer), int(amount));
        vaults.giveDai(self, amount*price);
        uint256 priceMultiplier = 10**27;
        auctioneer.update("priceMultiplier", priceMultiplier);
        auctioneer.update("tau", 60);
        auctioneer.update("maxDuration", 60);

        vaults.updatePrice(tokenId, price);
        uint auctionId = auctioneer.startAuction(amount*price, amount, self);
        cheats.warp(block.timestamp+61*1000);


        cheats.expectRevert(bytes("Auctioneer: auction has to be reset. Either the minimum price or maximum duration was reached."));
        auctioneer.buy(auctionId, amount, price, self);

        cheats.expectEmit(true, false, false, true);
        emit RestartAuction(auctionId, price, price*amount, amount, self);
        auctioneer.restartAuction(auctionId);
        (uint256 activeIndex, uint256 debt, uint256 collateral,
            address vaultOwner, uint96 startTime, uint256 startPrice) =auctioneer.auctions(auctionId);

        assertEq(startTime, uint96(block.timestamp));
    }

    function testRestartAuctionNeverStarted() public {
        cheats.expectRevert(bytes("Auctioneer: action was never started so it cannot be restarted"));
        auctioneer.restartAuction(0);
    }
    function testRestartAuctionStillActive() public {
        uint price = 10**27;
        uint amount = 200;

        vaults.updatePrice(tokenId, price);
        vaults.changeTokenBalance(tokenId, address(auctioneer), int(amount));
        vaults.giveDai(self, amount*price);
        uint256 priceMultiplier = 10**27;
        auctioneer.update("priceMultiplier", priceMultiplier);
        auctioneer.update("tau", 60);
        auctioneer.update("maxDuration", 60);

        vaults.updatePrice(tokenId, price);
        uint auctionId = auctioneer.startAuction(amount*price, amount, self);

        cheats.expectRevert(bytes("Auctioneer: Auction is still active and cannot be restarted"));
        auctioneer.restartAuction(auctionId);
    }

    function testRestartAuctionPrice0() public {
        uint price = 10**27;
        uint amount = 200;

        vaults.changeTokenBalance(tokenId, address(auctioneer), int(amount));
        vaults.giveDai(self, amount*price);
        uint256 priceMultiplier = 10**27;
        auctioneer.update("priceMultiplier", priceMultiplier);
        auctioneer.update("tau", 60);
        auctioneer.update("maxDuration", 60);

        vaults.updatePrice(tokenId, 0);
        uint auctionId = auctioneer.startAuction(amount*price, amount, self);
        cheats.warp(block.timestamp+61*1000);

        cheats.expectRevert(bytes("Auctioneer: starting price must be greater than 0"));
        auctioneer.restartAuction(auctionId);
    }

}