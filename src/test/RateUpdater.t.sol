// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;

import "ds-test/test.sol";
import "../RateUpdater.sol";
import "./CheatCodes.sol";
import "../Vaults.sol";

contract RateUpdaterTest is DSTest {
    RateUpdater rateUpdater; 
    CheatCodes cheats = CheatCodes(HEVM_ADDRESS);
    Vaults vaults;

    bytes32 tokenId = "Token";
    address self = address(this);
    address constant user1 = 0xE0f5206BBD039e7b0592d8918820024e2a7437b9;
    address constant user2 = 0xAb5801a7D398351b8bE11C439e05C5B3259aeC9B;

    function setUp() public {
        vaults = new Vaults();
        rateUpdater = new RateUpdater(address(vaults));
        vaults.authorize(address(rateUpdater));
    }

    function testUpdateRate() public {
        rateUpdater.addCollateralType(tokenId);
        vaults.addCollateralType(tokenId);

        (,uint256 rate,)= vaults.collateralTypes(tokenId);

        assertEq(rate, 10**27);

        rateUpdater.updateRate(tokenId);
        (,rate,)= vaults.collateralTypes(tokenId);
        assertEq(rate, 10**27);

        cheats.warp(block.timestamp+ 24*60*60*1000);

        rateUpdater.updateRate(tokenId);
        (,rate,)= vaults.collateralTypes(tokenId);
        assertEq(rate, 10**27);

        rateUpdater.update(tokenId, "fee",10**27 +1);
        cheats.warp(block.timestamp+ 24*60*60*1000);

        rateUpdater.updateRate(tokenId);
        (,rate,)= vaults.collateralTypes(tokenId);
        assertEq(rate, 1000000000000000000086400000);

        cheats.warp(block.timestamp+ 24*60*60*1000);

        rateUpdater.updateRate(tokenId);
        (,rate,)= vaults.collateralTypes(tokenId);
        assertEq(rate, 1000000000000000000172800000);

    }
}