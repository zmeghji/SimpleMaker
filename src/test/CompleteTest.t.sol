// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;

import "ds-test/test.sol";
import "./CheatCodes.sol";

import "../Vaults.sol";
import "../CollateralToken.sol";
import "../TokenBridge.sol";
import "../DaiBridge.sol";
import "../Dai.sol";

contract Token is CollateralToken{
    constructor() CollateralToken("Token", "TKN"){}
}

contract CompleteTest is DSTest {
    Vaults vaults ; 
    Token token;
    TokenBridge tokenBridge; 
    Dai dai;
    DaiBridge daiBridge; 
    CheatCodes cheats = CheatCodes(HEVM_ADDRESS);

    address self = address(this);
    address constant user1 = 0xE0f5206BBD039e7b0592d8918820024e2a7437b9;
    address constant user2 = 0xAb5801a7D398351b8bE11C439e05C5B3259aeC9B;
    bytes32 tokenId = "TKN";
    uint256 price = 3*10**27;
    function setUp() public {
        vaults = new Vaults();
        token = new Token();
        tokenBridge = new TokenBridge(address(vaults), tokenId, address(token));
        dai = new Dai();
        daiBridge = new DaiBridge(address(vaults), address(dai));


        //authorize 
        vaults.authorize(address(tokenBridge));
        dai.authorize(address(daiBridge));

        //setup
        vaults.addCollateralType(tokenId);
        vaults.updatePrice(tokenId, price);
    }

    function testOpenAndCloseVault() public {
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

        // assertEq(maxNormalizedDebt, 1);
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

        //close vault

        //withdraw tokens from maker protocol


    }
    function testLiquidate() public {
        // cheats.prank(user1);

        // uint256 totalTokens = 10;

        // //User mints tokens 
        // token.faucet();
        // assertEq(token.balanceOf(user1), totalTokens);

        // //User adds tokens to Maker protocol
        // token.approve(address(tokenBridge), totalTokens);
        // tokenBridge.enter(user1, totalTokens);
        // assertEq(token.balanceOf(user1), 0);
        // assertEq(vaults.tokenBalance(tokenId, user1), totalTokens);

        // //Open a vault
        // uint256 maxNormalizedDebt = price*totalTokens/ 10**27;
        // vaults.modifyVault(tokenId, user1, user1, user1, totalTokens, maxNormalizedDebt);
        // assertEq(vaults.tokenBalance(tokenId, user1), 0);
        // assertEq(vaults.daiBalance(tokenId, user1), price*totalTokens/ 10**27);
        // (uint256 collateral, uint256 normalizedDebt) = vaults.vaults(tokenId, self);
        // assertEq(totalTokens, collateral);
        // assertEq(normalizedDebt, maxNormalizedDebt);

        // wait for some time 
        // update the rates 
        // liquidate the vault 
        // kick off the auction 
    }

}