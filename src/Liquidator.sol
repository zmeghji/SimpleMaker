// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;

import "./Vaults.sol";
import "./Auth.sol";
import "./Auctioneer.sol";

/**@title Vault Liquidator and Collateral Auction Starter */
contract Liquidator is Auth {
    
    /**@dev stores details of collateral tokens */
    struct CollateralType{
        address auctioneer;
        uint256 penalty;
    }

    Vaults vaults;

    /**@dev tokenId => CollateralType */    
    mapping (bytes32 => CollateralType) public collateralTypes ;

    /**@dev Fired when vault is liquidated and auction has been triggered */
    event Liquidate(
      bytes32 indexed tokenId,
      address indexed vaultOwner,
      uint256 collateral,
      uint256 normalizedDebt,
      uint256 debt,
      address Auctioneer,
      uint256 indexed auctionId
    );

    /**@dev fired when information within the CollateralType has been changed */
    event Update(bytes32 indexed tokenId, bytes32 indexed field, uint256 newValue);
    event Update(bytes32 indexed tokenId, bytes32 indexed field, address newValue);

    constructor(address _vaults){
        vaults= Vaults(_vaults);
    }

    /**@dev Allows updating of liquidation penalty for collateral type */
    function update(bytes32 tokenId, bytes32 field, uint256 newValue) external auth {

        if (field == "penalty"){
            require(newValue >= 10**18, "Liquidator: penalty must be greater than or equal to 10**18");
            collateralTypes[tokenId].penalty = newValue;
        }
        else revert("Liquidator: unrecognized field");
        emit Update(tokenId, field, newValue);
    }

    /**@dev Allows updating of auctioneer contract for collateral type */
    function update(bytes32 tokenId, bytes32 field, address newValue) external auth {
        if (field == "auctioneer") {
            require(tokenId == Auctioneer(newValue).tokenId(), 
                "Liquidator: tokenId of auctioneer address provided does not match provided tokenId");
            collateralTypes[tokenId].auctioneer = newValue;
        } 
        else revert("Liquidator: unrecognized field");

        emit Update(tokenId, field, newValue);
    }

    /**@dev 
        Liquidates vault if the debt exceeds the collateral. 
        An auction is started by calling the startAuction method on the Auctioneer contract.
        Will fail if the collateral value exceeds debt
        Will fail if there is no collateral to auction in the vault  */
    function liquidate(bytes32 tokenId, address vaultOwner) public{

        (uint256 collateral, uint256 normalizedDebt) = vaults.vaults(tokenId, vaultOwner);
        (,uint256 rate,uint256 price) =vaults.collateralTypes(tokenId);

        CollateralType memory collateralType = collateralTypes[tokenId];

        require(collateral>0, "Liquidator: no collateral to auction");
        require(collateral*price < normalizedDebt*rate, "Liquidator: vault is under good standing and not eligible for liquidation");

        vaults.confiscate(tokenId, vaultOwner, collateralType.auctioneer, int256(collateral), int256(normalizedDebt));
        
        uint debtToPay = (normalizedDebt*rate*collateralType.penalty)/ 10**18;

        //Trigger auction
        uint256 auctionId = Auctioneer(collateralType.auctioneer).startAuction(debtToPay, collateral, vaultOwner);
        
        //emit event
        emit Liquidate(tokenId, vaultOwner, collateral, normalizedDebt, debtToPay, collateralType.auctioneer, auctionId);

    }
}