// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;

import "./Vaults.sol";
import "./Auth.sol";


//TODO add docs 
contract Liquidator is Auth {
    
    struct CollateralType{
        address auctioneer;
        uint256 penalty;
    }

    Vaults vaults;

    mapping (bytes32 => CollateralType) collateralTypes;

    constructor(address _vaults){
        vaults= Vaults(_vaults);
    }

    //TODO complete implementation
    //TODO add tests
    function liquidate(bytes32 tokenId, address vaultOwner, address beneficiary) public{

        //TODO for now only supporting total liquidation, consider supporting partial liquidation later

        (uint256 collateral, uint256 normalizedDebt) = vaults.vaults(tokenId, vaultOwner);
        (,uint256 rate,uint256 price) =vaults.collateralTypes(tokenId);

        CollateralType memory collateralType = collateralTypes[tokenId];

        require(collateral>0, "Liquidator: no collateral to auction");
        require(collateral*price < normalizedDebt*rate, "Liquidator: vault is under good standing and not eligible for liquidation");

        vaults.confiscate(tokenId, vaultOwner, collateralType.auctioneer, -int256(collateral), -int256(normalizedDebt));
        
        uint debtToPay = (normalizedDebt*rate*collateralType.penalty)/ 10**18;

        //Trigger auction
        //emit event


    }
}