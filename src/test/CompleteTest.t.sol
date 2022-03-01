// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;

import "ds-test/test.sol";
import "./CheatCodes.sol";

import "../Vaults.sol";
import "../CollateralToken.sol";
import "../TokenBridge.sol";
import "../DaiBridge.sol";
import "../Dai.sol";
import "../RateUpdater.sol";
import "../Liquidator.sol";
import "../Auctioneer.sol";

contract Token is CollateralToken{
    constructor() CollateralToken("Token", "TKN"){}
}

contract CompleteTest is DSTest {
    Vaults vaults ; 
    Token token;
    TokenBridge tokenBridge; 
    Dai dai;
    DaiBridge daiBridge; 
    RateUpdater rateUpdater; 
    Liquidator liquidator; 
    Auctioneer auctioneer;

    CheatCodes cheats = CheatCodes(HEVM_ADDRESS);

    address self = address(this);
    address constant user1 = 0xE0f5206BBD039e7b0592d8918820024e2a7437b9;
    address constant user2 = 0xAb5801a7D398351b8bE11C439e05C5B3259aeC9B;
    bytes32 tokenId = "TKN";
    uint256 price = 3*10**27;
    
    function setUp() public {
        vaults = new Vaults();
        token = new Token();
        dai = new Dai();
        tokenBridge = new TokenBridge(address(vaults), tokenId, address(token));
        daiBridge = new DaiBridge(address(vaults), address(dai));
        rateUpdater = new RateUpdater(address(vaults));
        liquidator = new Liquidator(address(vaults));
        auctioneer = new Auctioneer(address(vaults), tokenId);

        //authorize 
        vaults.authorize(address(tokenBridge));
        vaults.authorize(address(rateUpdater));
        dai.authorize(address(daiBridge));
        auctioneer.authorize(address(liquidator));

        //setup
        vaults.addCollateralType(tokenId);
        vaults.updatePrice(tokenId, price);
        rateUpdater.addCollateralType(tokenId);
        rateUpdater.update(tokenId, "fee",10**27 +1);
        liquidator.update(tokenId, "auctioneer", address(auctioneer));
        liquidator.update(tokenId, "penalty", 10**18); //consider changing the penalty this is effectively a zero liquidation fee

        auctioneer.update("maxDuration", 60*60*24);
        auctioneer.update("tau", 60*60*24);
        auctioneer.update("priceMultiplier", 10**27);

    }

    function testFaucet() public {
        cheats.startPrank(user1);
        uint256 totalTokens =99;
        token.faucet(totalTokens);
        assertEq(token.balanceOf(user1), totalTokens);
    }

    function testVaultOperations() public {
        cheats.startPrank(user1);

        uint256 totalTokens = 10;

        //User mints tokens 
        token.faucet();
        assertEq(token.balanceOf(user1), totalTokens);

        //User adds tokens to Maker protocol
        token.approve(address(tokenBridge), totalTokens);
        tokenBridge.enter(user1, totalTokens);
        assertEq(token.balanceOf(user1), 0);
        assertEq(vaults.tokenBalance(tokenId, user1), totalTokens);

        //Open a vault
        uint256 maxNormalizedDebt = price*totalTokens/ 10**27;
        vaults.modifyVault(tokenId, user1, user1, user1, int256(totalTokens), int256(maxNormalizedDebt));

        assertEq(vaults.tokenBalance(tokenId, user1), 0);
        assertEq(vaults.daiBalance( user1), maxNormalizedDebt*10**27);
        (uint256 collateral, uint256 normalizedDebt) = vaults.vaults(tokenId, user1);
        assertEq(totalTokens, collateral);
        assertEq(normalizedDebt, maxNormalizedDebt);

        //Withdraw dai
        vaults.delegate(address(daiBridge));
        daiBridge.exit(user1, maxNormalizedDebt);
        assertEq(vaults.daiBalance( user1), 0);
        assertEq(dai.balanceOf(user1), maxNormalizedDebt);

        //Put dai back into maker protocol
        dai.approve(address(daiBridge), maxNormalizedDebt);
        daiBridge.enter(user1, maxNormalizedDebt);
        assertEq(vaults.daiBalance( user1), (maxNormalizedDebt)*10**27);
        assertEq(dai.balanceOf(user1), 0);

        // remove vault debt and collateral by half
        vaults.modifyVault(tokenId, user1, user1, 
            user1, -int(totalTokens), -int(maxNormalizedDebt));

        assertEq(vaults.tokenBalance(tokenId, user1), totalTokens);
        assertEq(vaults.daiBalance( user1), 0);
        (collateral, normalizedDebt) = vaults.vaults(tokenId, user1);
        assertEq(collateral,0);
        assertEq(normalizedDebt, 0);


        //withdraw tokens from maker protocol
        tokenBridge.exit(user1, totalTokens);
        assertEq(vaults.tokenBalance(tokenId, user1), 0);
        assertEq(token.balanceOf(user1), totalTokens);


    }
    function testLiquidate() public {
        /**
            1. open vaults for user1 and user2
            2. wait for some time
            3. update the rate of the token
            4. user2 liquidates the vault of user1
            5. user2 buys the collateral in the auction
        */

        uint totalTokens =10;

        //open vault for user1 and user 2
        openVaultForUser(user1);
        openVaultForUser(user2);

        cheats.startPrank(user2);
        // wait for 1 day
        cheats.warp(24*60*60*1000);

        // update the rates 
        rateUpdater.updateRate(tokenId);
        (,uint256 rate,) = vaults.collateralTypes(tokenId);
        assertEq(rate, 1000000000000000000086400000);

        // liquidate the vault 
        cheats.startPrank(user2);
        liquidator.liquidate(tokenId, user1);

        (uint256 collateral, uint256 normalizedDebt) = vaults.vaults(tokenId, user1);
        assertEq(collateral, 0);
        assertEq(normalizedDebt, 0);
        assertEq(vaults.tokenBalance(tokenId, address(auctioneer)), totalTokens);

        //buy collateral from auction
        vaults.delegate(address(auctioneer));
        assertEq(vaults.tokenBalance(tokenId,user2), 0);
        assertEq(vaults.daiBalance(user2), price*totalTokens);

        auctioneer.buy(0, totalTokens, price, user2);
        
        assertEq(vaults.tokenBalance(tokenId,user2), totalTokens);
        assertEq(vaults.daiBalance(user2), 0);

    }

    function testSelfLiquidate() public {
        /**
            1. open vaults for user1 
            2. wait for some time
            3. update the rate of the token
            4. user1 liquidates their own vault
            5. user1 buys the collateral in the auction
        */

        uint totalTokens =10;

        //open vault for user1 
        openVaultForUser(user1);
        cheats.startPrank(user1);
        // wait for 1 day
        cheats.warp(24*60*60*1000);

        // update the rates 
        rateUpdater.updateRate(tokenId);
        (,uint256 rate,) = vaults.collateralTypes(tokenId);
        assertEq(rate, 1000000000000000000086400000);

        // liquidate the vault 
        liquidator.liquidate(tokenId, user1);

        (uint256 collateral, uint256 normalizedDebt) = vaults.vaults(tokenId, user1);
        assertEq(collateral, 0);
        assertEq(normalizedDebt, 0);
        assertEq(vaults.tokenBalance(tokenId, address(auctioneer)), totalTokens);

        //buy collateral from auction
        vaults.delegate(address(auctioneer));
        assertEq(vaults.tokenBalance(tokenId,user1), 0);
        assertEq(vaults.daiBalance(user1), price*totalTokens);

        auctioneer.buy(0, totalTokens, price, user1);

        assertEq(vaults.tokenBalance(tokenId,user1), totalTokens);
        assertEq(vaults.daiBalance(user1), 0);

    }
    
    function openVaultForUser(address user) private{
        cheats.startPrank(user);

        uint256 totalTokens = 10;

        //User mints tokens 
        token.faucet();

        //User adds tokens to Maker protocol
        token.approve(address(tokenBridge), totalTokens);
        tokenBridge.enter(user, totalTokens);
     
        //Open a vault
        uint256 maxNormalizedDebt = price*totalTokens/ 10**27;
        vaults.modifyVault(tokenId, user, user, user, int256(totalTokens), int256(maxNormalizedDebt));

        cheats.stopPrank();
    }

}