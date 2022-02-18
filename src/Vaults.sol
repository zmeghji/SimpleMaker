// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;

import "./Auth.sol";
import "./Delegate.sol";
import "./MathLib.sol";

//TODO add documentation on contract level
contract Vaults is Auth, Delegate{
    using MathLib for uint256;

    /**@dev 
        stores collateral type.
        rate*normalizedDebt corresponds to actual debt */
    struct CollateralType {
        uint256 normalizedDebt;
        uint256 rate;
        uint256 price;
    }

    /**@dev represents vault with locked collateral and amount of debt*/
    struct Vault {
        uint256 collateral;
        uint256 normalizedDebt;
    }

    /**dev
        tokenId => CollateralType*/
    mapping (bytes32 => CollateralType) public collateralTypes;

    mapping (bytes32 => mapping(address => Vault)) public vaults;

    /**@dev 
        tokenIdentifier => (user => amount)
        Represents the balance of tokens for each user within the maker protocol*/
    mapping (bytes32 => mapping (address => uint)) public tokenBalance; 

    /**@dev 
        user => amount
        Represents the balance of dai available to each user within the maker protocol */
    mapping (address => uint256) public daiBalance; 


    /**@dev 
        adds a new collateral type. Fails if the collateral type has already been added.
        Fails if the caller is not an authorized address */
    function addCollateralType(bytes32 tokenId) external auth {
        require(collateralTypes[tokenId].rate == 0, "Vault: collateral type with tokenId already added");
        collateralTypes[tokenId].rate = 10 ** 27;
    }
    
    /**@dev 
        Updates price of existing collateral type. 
        Fails if the caller is not an authorized address */
    function updatePrice(bytes32 tokenId, uint newPrice) external auth{
        collateralTypes[tokenId].price = newPrice;
    }
    
    /**@dev 
        changes the token balance of a user by the specified amount. 
        Can only be called by authorized addresses */
    function changeTokenBalance(bytes32 tokenId, address user, int256 amount) external auth {
        tokenBalance[tokenId][user] =tokenBalance[tokenId][user].add(amount);
    }

    /**@dev 
        moves specified amount of  tokens between source and destination
        msg.sender must be a delegate of the source address  */
    function moveTokens(bytes32 tokenId, address src, address dst, uint256 amount) external {
        require(isDelegate(src, msg.sender), "Vaults: msg.sender is not a delegate of src address");
        tokenBalance[tokenId][src] -= amount;
        tokenBalance[tokenId][dst] += amount;
    }

    /**@dev 
        moves specified amount of  dai between source and destination
        msg.sender must be a delegate of the source address  */
    function moveDai(address src, address dst, uint256 amount) external {
        require(isDelegate(src, msg.sender), "Vaults: msg.sender is not a delegate of src address");
        daiBalance[src] -= amount;
        daiBalance[dst] += amount;
    }

    /**@dev
        modifies a vault by adding/removing collateral and drawing/repaying dai. 
        Will fail if the operation makes the vault unsafe (collateral < debt) 
        Will fail if the vaultOwner,collateral provider or dai receiver are not delegates of the msg.sender
        daiReceiver will actually lose dai if normalizedDebtToAdd is negative
        collateralProvider wil actually gain collateral if collateralToAdd is negative*/
    function modifyVault(
        bytes32 tokenId, 
        address vaultOwner, 
        address collateralProvider,
        address daiReceiver,
        int collateralToAdd,
        int normalizedDebtToAdd) external{
        
        Vault memory vault = vaults[tokenId][vaultOwner];
        CollateralType memory collateralType = collateralTypes[tokenId];

        require(collateralType.rate != 0, "Vaults: collateral type has not been added");

        vault.collateral = vault.collateral.add(collateralToAdd);
        vault.normalizedDebt = vault.normalizedDebt.add(normalizedDebtToAdd);

        int debtChange = collateralType.rate.mul(collateralToAdd);
        uint totalDebt = collateralType.rate * vault.normalizedDebt;

        require(
            (totalDebt < (vault.collateral * collateralType.price)),
            "Vaults: total debt exceeds value of collateral"
        );

        require (isDelegate(msg.sender, vaultOwner ), "Vaults: msg.sender is not a delegate of vault owner");
        require (isDelegate(msg.sender, collateralProvider ), "Vaults: msg.sender is not a delegate of collateral provider");
        require (isDelegate(msg.sender, daiReceiver ), "Vaults: msg.sender is not a delegate of daiReceiver");


        tokenBalance[tokenId][collateralProvider] = tokenBalance[tokenId][collateralProvider].sub(collateralToAdd);
        daiBalance[daiReceiver] = daiBalance[daiReceiver].add(debtChange);

        vaults[tokenId][vaultOwner] = vault;
    }

    // initial goal should be to simply update balances of gems and dai, and open vaults
    // implement Vault tests

}        
    
