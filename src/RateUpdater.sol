// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;

import "./Vaults.sol";
import "./Auth.sol";

/**@title Updates the stability fee rate of a collateral type within the Vaults contract */
contract RateUpdater is Auth {

    /**@dev base fee rate which applies to all collateral types*/
    uint256 baseFee;

    /**@dev holds collateral-specific fee rate and time it was last updated */
    struct CollateralType{
        uint256 fee;
        uint256 lastUpdated;
    }
    
    Vaults vaults;

    /**@dev (tokenId => CollateralType) */
    mapping (bytes32 => CollateralType) public collateralTypes;

    /**emitted when base fee is updated */
    event Update(bytes32 field, uint256 newValue);
    /**emitted when collateral-speficic fee is updated */
    event Update(bytes32 tokenId, bytes32 field, uint256 newValue);

    constructor (address _vaults) {
        vaults = Vaults(_vaults);
    }

    /**@dev 
        initialize Collateral Type within RateUpdater contract
        fails if collateral type has already been intialized */
    function addCollateralType(bytes32 tokenId) external auth {
        CollateralType storage collateralType = collateralTypes[tokenId];

        require(collateralType.fee == 0, "RateUpdater: collateral has already been added");

        collateralType.fee = 10**27;
        collateralType.lastUpdated = block.timestamp;
    }

    /**@dev updates base fee which applies to all collateral types. emits Update event */
    function update(bytes32 field, uint256 newValue) external{
        if (field == "baseFee"){
            baseFee= newValue;
        }
        else{
            revert("RateUpdater: field not recognized");
        }
        emit Update(field, newValue);
    }

    /**@dev updates collateral-specific fee which applies to all collateral types. emits Update event */
    function update(bytes32 tokenId, bytes32 field, uint256 newValue) external{
        if (field == "fee"){
            collateralTypes[tokenId].fee = newValue;
        }
        else{
            revert("RateUpdater: field not recognized");
        }
        emit Update(tokenId, field, newValue);
    }

    /**@dev updates rate for collateral type within Vaults contract */
    function updateRate(bytes32 tokenId) external returns (uint256 newRate){
        (,uint256 rate,) = vaults.collateralTypes(tokenId);
        uint256 tmp = rpow(baseFee+collateralTypes[tokenId].fee, block.timestamp - collateralTypes[tokenId].lastUpdated, 10**27);
        newRate = (tmp*rate)/10**27;
        
        vaults.updateRate(tokenId, newRate);
        collateralTypes[tokenId].lastUpdated = block.timestamp;
    }


    /**@dev taken from jug contract of Maker protocol. Calculates x**n */
    function rpow(uint x, uint n, uint b) internal pure returns (uint z) {
      assembly {
        switch x case 0 {switch n case 0 {z := b} default {z := 0}}
        default {
          switch mod(n, 2) case 0 { z := b } default { z := x }
          let half := div(b, 2)  // for rounding.
          for { n := div(n, 2) } n { n := div(n,2) } {
            let xx := mul(x, x)
            if iszero(eq(div(xx, x), x)) { revert(0,0) }
            let xxRound := add(xx, half)
            if lt(xxRound, xx) { revert(0,0) }
            x := div(xxRound, b)
            if mod(n,2) {
              let zx := mul(z, x)
              if and(iszero(iszero(x)), iszero(eq(div(zx, x), z))) { revert(0,0) }
              let zxRound := add(zx, half)
              if lt(zxRound, zx) { revert(0,0) }
              z := div(zxRound, b)
            }
          }
        }
      }
    }
}