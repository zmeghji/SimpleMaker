// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;

import "./Auth.sol";
import "./Vaults.sol";
import "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import "openzeppelin-contracts/contracts/security/ReentrancyGuard.sol";
import "./MathLib.sol";

/**@title Auctioneer of collateral confiscated from liquidated vaults */
contract Auctioneer is Auth,ReentrancyGuard{

    /**@dev holds information on specific collateral auctions */
    struct Auction{
        uint256 activeIndex;
        uint256 debt;
        uint256 collateral;
        address vaultOwner;
        uint96 startTime;
        uint256 startPrice;
    }

    /**@dev Maximum number of seconds an auction can last for before having to be reset */
    uint256 public maxDuration;  
    /**@dev Maximum price drop percent before the auction has to be reset */
    uint256 public maxPriceDrop;
    /**@dev  Seconds after auction start when the price reaches zero */ 
    uint256 public tau; 
    bytes32 public tokenId;
    /**@dev holds auction Ids of active auctions */
    uint256[] public active;    
    /**@dev the next auction will use this id */
    uint256 public nextAuctionId;
    /**@dev Multiply the current price of the collateral by this number to get the starting price of the auction */
    uint256 public priceMultiplier;

    Vaults vaults;

    constructor(address _vaults, bytes32 _tokenId){
        vaults = Vaults(_vaults);
        tokenId = _tokenId;
    }

    /**@dev 
        auctionId => Auction */
    mapping(uint256 => Auction) public auctions;

    /**@dev Emitted when auction has been started */
    event StartAuction (
        uint256 indexed id,
        uint256 startAmount,
        uint256 debt,
        uint256 collateral,
        address indexed vaultOwner
    );

    /**@dev Emitted when a user has bought collateral from an auction*/
    event Buy(
        uint256 indexed auctionid,
        uint256 maxPrice,
        uint256 price,
        uint256 daiPaid,
        uint256 remainingDebt,
        uint256 remainingCollateral,
        address indexed vaultOwner
    );

    /**@dev Emitted when an auction has been restarted*/
    event RestartAuction(
        uint256 indexed id,
        uint256 startPrice,
        uint256 debt,
        uint256 collateral,
        address indexed vaultOwner
    );
    /**@dev emitted when a contract storage variable is updated e.g. priceMultiplier, maxDuration, maxPriceDrop */
    event Update(bytes32 indexed field, uint256 newValue);
    
    /**@dev 
        updates contract configuration variables. Fails if the speficied field/variable name doesn't exist.
        Emits Update event */
    function update(bytes32 field, uint256 newValue) external auth nonReentrant {
        if (field == "priceMultiplier"){ 
            priceMultiplier = newValue;
        }
        else if (field == "maxDuration"){
            maxDuration = newValue; 
        }
        else if (field == "maxPriceDrop"){
            maxPriceDrop = newValue;
        }
        else if (field == "tau"){
            tau = newValue;
        }
        else {
            revert("Auctioneer: unrecognized field name");
        }

        emit Update(field, newValue);
    }

    /**@dev starts an auction. Emits StartAuction event */
    function startAuction(
        uint256 debt,
        uint256 collateral,
        address vaultOwner
    ) external auth nonReentrant returns (uint256 id){
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
        uint256 startPrice = (getPrice()*priceMultiplier)/10**27;
        auctions[id].startPrice = startPrice;

        emit StartAuction(id, startPrice, debt, collateral, vaultOwner);//
    }
    
    /** @dev
        Restarts an auction. Fails if the auction was never started or if it is still active.  
        Emits RestartAuction event. */
    function restartAuction(uint256 auctionId) external nonReentrant {
        address vaultOwner = auctions[auctionId].vaultOwner;
        uint96 startTime = auctions[auctionId].startTime;
        uint256 startPrice = auctions[auctionId].startPrice;
        require( vaultOwner != address(0), "Auctioneer: action was never started so it cannot be restarted");

        (bool done,) = status(startTime, auctions[auctionId].startPrice);

        require(done, "Auctioneer: Auction is still active and cannot be restarted");

        uint256 debt = auctions[auctionId].debt;
        uint256 collateral = auctions[auctionId].collateral;
        auctions[auctionId].startTime = uint96(block.timestamp);

        uint256 price = getPrice();
        startPrice = (price* priceMultiplier)/10**27;
        require(startPrice>0, "Auctioneer: starting price must be greater than 0");
        auctions[auctionId].startPrice = startPrice;

        emit RestartAuction(auctionId, startPrice, debt, collateral, vaultOwner);

    }

    /**@dev allows user to buy collateral in auction. emits Buy event. */
    function buy(
        uint256 auctionId,
        uint256 maxCollateralToBuy,
        uint256 maxPrice,
        address receiver
    ) external{
        address vaultOwner = auctions[auctionId].vaultOwner;
        uint96 startTime = auctions[auctionId].startTime;

        require( vaultOwner != address(0), "Auctioneer: action has not been started");

        (bool done, uint256 price) = status(startTime, auctions[auctionId].startPrice);

        require(!done, "Auctioneer: auction has to be reset. Either the minimum price or maximum duration was reached.");
        require(maxPrice >= price, "Auctioneer: Current price exceeds requested maximum price");

        uint256 collateral = auctions[auctionId].collateral;
        uint256 debt = auctions[auctionId].debt;

        uint256 collateralToBuy =MathLib.min(collateral, maxCollateralToBuy);
        uint256 daiToPay = collateralToBuy* price;

        //even if total dai offered is more than debt, still only buy enough collateral to cover debt
        if (daiToPay> debt){
            daiToPay = debt;
            collateralToBuy = daiToPay/price;
        }

        //collateral and debt after buy
        collateral -= collateralToBuy;
        debt -= daiToPay;

        vaults.moveTokens(tokenId, address(this), receiver, collateralToBuy);
        //In the real Maker protocol is sent to the vow contract, not to 0 address
        vaults.moveDai(msg.sender, address(0), daiToPay);

        if (collateral == 0) {
            endAuction(auctionId);
        } else if (debt == 0) {
            vaults.moveTokens(tokenId, address(this), vaultOwner, collateral);
            endAuction(auctionId);
        } else {
            auctions[auctionId].collateral = collateral;
            auctions[auctionId].debt = debt;
        }
        emit Buy(auctionId, maxPrice, price, daiToPay, debt, collateral, vaultOwner);
    }

    /**@dev internal function to end auction by removing it from list of active auctions */
    function endAuction(uint256 id) internal {
        uint256 move    = active[active.length - 1];
        if (id != move) {
            uint256 index   = auctions[id].activeIndex;
            active[index]   = move;
            auctions[move].activeIndex = index;
        }
        active.pop();
        delete auctions[id];
    }
    /**@dev returns whether the auction has finished and what the current price of the collateral within the auction is */
    function status(uint96 startTime, uint256 startPrice) internal view returns (bool done, uint256 price) {
        uint256 duration = block.timestamp-startTime;
        if (duration > tau){
            price = 0;
        }
        else{
            price = (startPrice * (tau - duration)* 10**27 / tau)/ 10**27;
        }
        
        done  = (duration > maxDuration || (price*10**27)/startPrice < maxPriceDrop);
    }

    /**@dev
        Gets current price from the vaults contract.
        In the real Maker protocol this is received directly from the oracle security module */
    function getPrice() internal view  returns (uint256 price) {
        (,, price) =vaults.collateralTypes(tokenId);
    }
}