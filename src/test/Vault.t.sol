// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;

import "ds-test/test.sol";
import "../Vaults.sol";
import "./CheatCodes.sol";
import "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import "../TokenBridge.sol";
import "../Dai.sol";
import "../DaiBridge.sol";

contract VaultsWithMint is Vaults{
    function giveDai(address to, uint256 amount) public{
        daiBalance[to] += amount;
    }
}
contract Token is ERC20 {
    constructor() ERC20("Token", "TKN") {
        _mint(msg.sender, 10000 * 10 ** decimals());
    }
}
contract VaultsTest is DSTest {
    VaultsWithMint vaults; 
    TokenBridge tokenBridge; 
    Token token; 
    Dai dai;
    DaiBridge daiBridge; 
    CheatCodes cheats = CheatCodes(HEVM_ADDRESS);
    bytes32 tokenId  ="Token";

    address self = address(this);
    function setUp() public {
        vaults = new VaultsWithMint();

        dai = new Dai();
        daiBridge = new DaiBridge(address(vaults), address(dai));

        token = new Token();
        tokenBridge = new TokenBridge(address(vaults), tokenId, address(token));
        vaults.authorize(address(tokenBridge));
    }

    address constant user1 = 0xE0f5206BBD039e7b0592d8918820024e2a7437b9;
    address constant user2 = 0xAb5801a7D398351b8bE11C439e05C5B3259aeC9B;

    function testAddCollateralType() public {
        (,uint256 rate,) =vaults.collateralTypes(tokenId);
        assertEq(rate, 0);
        vaults.addCollateralType(tokenId);
        (,rate,) =vaults.collateralTypes(tokenId);
        assertEq(rate, 10**27 );
    }

    function testAddCollateralTypeTwice() public {
        vaults.addCollateralType(tokenId);
        cheats.expectRevert(bytes("Vault: collateral type with tokenId already added"));
        vaults.addCollateralType(tokenId);
    }

    function testAddCollateralTypeUnauthorized() public{
        cheats.startPrank(user1);
        cheats.expectRevert(bytes("Auth: msg.sender is not authorized"));
        vaults.addCollateralType(tokenId);
    }

    function testUpdatePrice() public{
        vaults.addCollateralType(tokenId);
        (,,uint256 price) =vaults.collateralTypes(tokenId);
        assertEq(price, 0);

        uint newPrice = 100;
        vaults.updatePrice(tokenId, newPrice);
        (,,price) =vaults.collateralTypes(tokenId);
        assertEq(price, newPrice);

    }
    function testUpdatePriceUnauthorized() public{
        vaults.addCollateralType(tokenId);
        cheats.startPrank(user1);
        cheats.expectRevert(bytes("Auth: msg.sender is not authorized"));
        vaults.updatePrice(tokenId, 100);
    }

    function testChangeTokenBalance() public {
        vaults.addCollateralType(tokenId);
        assertEq(vaults.tokenBalance(tokenId, user1),0);

        int256 newBalance =100;
        vaults.changeTokenBalance(tokenId, user1, newBalance);        
        assertEq(vaults.tokenBalance(tokenId, user1),uint256(newBalance));
    }

    function testChangeTokenBalanceUnderflow() public {
        vaults.addCollateralType(tokenId);
        assertEq(vaults.tokenBalance(tokenId, user1),0);
        int256 newBalance =-100;

        cheats.expectRevert(bytes("MathLib: add underflow"));
        vaults.changeTokenBalance(tokenId, user1, newBalance);        
    }

    function testChangeTokenBalanceUnauthorized() public{
        vaults.addCollateralType(tokenId);
        cheats.startPrank(user1);
        cheats.expectRevert(bytes("Auth: msg.sender is not authorized"));
        vaults.changeTokenBalance(tokenId, user1, 100);
    }

    function testMoveTokens() public {
        vaults.addCollateralType(tokenId);
        int256 newBalance =100;
        vaults.changeTokenBalance(tokenId, user1, newBalance);        
        assertEq(vaults.tokenBalance(tokenId, user1),uint256(newBalance));
        assertEq(vaults.tokenBalance(tokenId, user2),0);

        cheats.prank(user1);
        vaults.moveTokens(tokenId, user1, user2, uint256(newBalance));

        assertEq(vaults.tokenBalance(tokenId, user1),0);
        assertEq(vaults.tokenBalance(tokenId, user2),uint256(newBalance));
    }

    function testFailMoveTokensNotEnoughToMove() public {
        vaults.addCollateralType(tokenId);
        int256 newBalance =100;
        vaults.changeTokenBalance(tokenId, user1, newBalance);        
        assertEq(vaults.tokenBalance(tokenId, user1),uint256(newBalance));
        assertEq(vaults.tokenBalance(tokenId, user2),0);

        cheats.startPrank(user1);
        vaults.moveTokens(tokenId, user1, user2, uint256(newBalance+1));
    }

    function testMoveTokensNotDelegate() public {
        vaults.addCollateralType(tokenId);
        int256 newBalance =100;
        vaults.changeTokenBalance(tokenId, user1, newBalance);        

        cheats.expectRevert(bytes("Vaults: msg.sender is not a delegate of src address"));
        vaults.moveTokens(tokenId, user1, user2, uint256(newBalance));

    }


    function testMoveDai() public {
        uint256 amount = 100;
        vaults.giveDai(user1, amount);
        assertEq(vaults.daiBalance(user1), amount);
        assertEq(vaults.daiBalance(user2), 0);

        cheats.prank(user1);
        vaults.moveDai(user1, user2, amount);

        assertEq(vaults.daiBalance(user1), 0);
        assertEq(vaults.daiBalance(user2), amount);
    }

    function testFailMoveDaiNotEnoughToMove() public {
         uint256 amount = 100;
        vaults.giveDai(user1, amount);
        assertEq(vaults.daiBalance(user1), amount);

        cheats.startPrank(user1);
        vaults.moveDai(user1, user2, amount+1);
    }

    function testMoveDaiNotDelegate() public {
        uint256 amount = 100;
        vaults.giveDai(user1, amount);
        assertEq(vaults.daiBalance(user1), amount);

        cheats.expectRevert(bytes("Vaults: msg.sender is not a delegate of src address"));
        vaults.moveDai(user1, user2, amount);
    }

    function testModifyVault() public {
        vaults.addCollateralType(tokenId);
        vaults.updatePrice(tokenId, 10**27);

        int256 balance =100;
        vaults.changeTokenBalance(tokenId, self, balance);        
        assertEq(vaults.tokenBalance(tokenId, self),uint256(balance));

        // rate * maxNormalizedDebt = price * collateral 
        // maxNormalizedDebt = price*collateral/rate
        int256 normalizedDebtToAdd = balance;

        vaults.modifyVault(tokenId, self, self, self, balance, normalizedDebtToAdd);


        (uint256 collateral, uint256 normalizedDebt) = vaults.vaults(tokenId, self);

        assertEq(collateral, uint256(balance));
        assertEq(normalizedDebt, uint256(balance));

        assertEq(vaults.tokenBalance(tokenId, self),0);
        assertEq(vaults.daiBalance(self), uint256(balance)*10**27);

    }

    function testModifyVaultCollateralNotInitialized() public {
        cheats.expectRevert(bytes("Vaults: collateral type has not been added"));
        vaults.modifyVault(tokenId, self, self, self, 100, 100);
    }

    function testModifyVaultNotSafe() public {
        vaults.addCollateralType(tokenId);
        vaults.updatePrice(tokenId, 10**27);

        int256 balance =100;
        vaults.changeTokenBalance(tokenId, self, balance);        

        int256 normalizedDebtToAdd = balance +1;

        cheats.expectRevert(bytes("Vaults: total debt exceeds value of collateral"));
        vaults.modifyVault(tokenId, self, self, self, balance, normalizedDebtToAdd);

    }

    function testModifyVaultNotDelegateOfVaultOwner() public {
        vaults.addCollateralType(tokenId);
        vaults.updatePrice(tokenId, 10**27);

        int256 balance =100;
        vaults.changeTokenBalance(tokenId, self, balance);        

        int256 normalizedDebtToAdd = balance;

        cheats.expectRevert(bytes("Vaults: msg.sender is not a delegate of vault owner"));
        vaults.modifyVault(tokenId, user1, self, self, balance, normalizedDebtToAdd);

    }

    function testModifyVaultNotDelegateOfCollateralProvider() public {
        vaults.addCollateralType(tokenId);
        vaults.updatePrice(tokenId, 10**27);

        int256 balance =100;
        vaults.changeTokenBalance(tokenId, self, balance);        

        int256 normalizedDebtToAdd = balance;

        cheats.expectRevert(bytes("Vaults: msg.sender is not a delegate of collateral provider"));
        vaults.modifyVault(tokenId, self, user1, self, balance, normalizedDebtToAdd);

    }

    function testModifyVaultNotDelegateOfDaiReceiver() public {
        vaults.addCollateralType(tokenId);
        vaults.updatePrice(tokenId, 10**27);

        int256 balance =100;
        vaults.changeTokenBalance(tokenId, self, balance);        

        int256 normalizedDebtToAdd = balance;

        cheats.expectRevert(bytes("Vaults: msg.sender is not a delegate of daiReceiver"));
        vaults.modifyVault(tokenId, self, self, user1, balance, normalizedDebtToAdd);

    }


    function testDepositOpenAndCloseVault() public{

        uint256 originalTokenBalance = token.balanceOf(self);
        vaults.addCollateralType(tokenId);
        vaults.updatePrice(tokenId, 10**27);

        uint256 amount = 200;
        token.approve(address(tokenBridge), amount);
        tokenBridge.enter(self, amount);

        assertEq(vaults.tokenBalance(tokenId, self), amount);
        assertEq(vaults.daiBalance(self), 0);


        //maxNormalizedDebt * rate = price* collateral
        // maxNormalizeDebt = price*collateral/rate  = collateral
        
        vaults.modifyVault(tokenId, self, self, self, int(amount), int(amount));

        assertEq(vaults.tokenBalance(tokenId, self), 0);
        (uint256 collateral, uint256 normalizedDebt) = vaults.vaults(tokenId, self);
        assertEq(collateral, amount);
        assertEq(normalizedDebt, amount);
        assertEq(vaults.daiBalance(self), amount*10**27);

        vaults.delegate(address(daiBridge));
        dai.authorize(address(daiBridge));
        daiBridge.exit(self, amount);

        assertEq(vaults.daiBalance(self), 0);
        assertEq(dai.balanceOf(self), amount);

        dai.approve(address(daiBridge), amount);
        daiBridge.enter(self, amount);
        assertEq(vaults.daiBalance(self), amount*10**27);
        assertEq(dai.balanceOf(self), 0);

        vaults.modifyVault(tokenId, self, self, self, -int(amount), -int(amount));

        assertEq(vaults.tokenBalance(tokenId, self), amount);
        ( collateral, normalizedDebt) = vaults.vaults(tokenId, self);
        assertEq(collateral, 0);
        assertEq(normalizedDebt, 0);
        assertEq(vaults.daiBalance(self), 0);

        tokenBridge.exit(self, amount);
        assertEq(vaults.tokenBalance(tokenId, self), 0);
        assertEq(token.balanceOf(self), originalTokenBalance);
    }


    function testConfiscate() public {
        vaults.addCollateralType(tokenId);
        vaults.updatePrice(tokenId, 10**27);

        int256 balance =100;
        vaults.changeTokenBalance(tokenId, self, balance);        
        assertEq(vaults.tokenBalance(tokenId, self),uint256(balance));

        int256 normalizedDebtToAdd = balance;

        vaults.modifyVault(tokenId, self, self, self, balance, normalizedDebtToAdd);

        (uint256 collateral, uint256 normalizedDebt) = vaults.vaults(tokenId, self);

        assertEq(collateral, uint256(balance));
        assertEq(normalizedDebt, uint256(balance));
        assertEq(vaults.tokenBalance(tokenId, user1), 0);

        vaults.confiscate(tokenId, self, user1, balance, balance);

        (collateral, normalizedDebt) = vaults.vaults(tokenId, self);

        assertEq(collateral, 0);
        assertEq(normalizedDebt, 0);
        assertEq(vaults.tokenBalance(tokenId,user1), uint(balance));
    }

}