// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;

import "./Auth.sol";
import "./Vaults.sol";

//TODO document
contract Auctioneer is Auth{

    struct Auction{
        uint256 activeIndex;
        uint256 debt;
        uint256 collateral;
        address vaultOwner;
        uint96 startTime;
        uint256 startPrice;
    }


    bytes32 public tokenId;
    uint256[] public active;    
    uint256 public nextAuctionId;
    uint256 public priceMultiplier;

    Vaults vaults;

    constructor(address _vaults, bytes32 _tokenId){
        vaults = Vaults(_vaults);
        tokenId = _tokenId;
    }

    mapping(uint256 => Auction) public auctions;


    event StartAuction (
        uint256 indexed id,
        uint256 startAmount,
        uint256 debt,
        uint256 collateral,
        address indexed vaultOwner
    );

    //TODO add circuit breaker modifier
    //TODO add reentrancy guard
    function startAuction(
        uint256 debt,
        uint256 collateral,
        address vaultOwner
    ) external auth returns (uint256 id){
        require(debt >0, "Auctioneer: debt is 0, nothing to auction");
        require(collateral > 0, "Auctioneer: collateral is 0, nothing to auction");
        require(vaultOwner != address(0), "");
        id = nextAuctionId++;

        active.push(id);

        auctions[id].activeIndex = active.length-1;
        auctions[id].debt = debt;
        auctions[id].collateral = collateral;
        auctions[id].vaultOwner = vaultOwner;
        auctions[id].startTime = uint96(block.timestamp);
        uint256 startAmount = (getPrice()*priceMultiplier)/10**27;
        auctions[id].startPrice = startAmount;


        //TODO implement incentives for beneficiary

        emit StartAuction(id, startAmount, debt, collateral, vaultOwner);//
    }
    

    function getPrice() internal returns (uint256 price) {
        //TODO change this to get the price from the oracle later
        (,, price) =vaults.collateralTypes(tokenId);
    }
}