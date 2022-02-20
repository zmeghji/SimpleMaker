// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;

import "ds-test/test.sol";
import "../TokenBridge.sol";
import "./CheatCodes.sol";
import "../Vaults.sol";
import "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

contract Token is ERC20 {
    constructor() ERC20("Token", "TKN") {
        _mint(msg.sender, 10000 * 10 ** decimals());
    }
}


contract TokenBridgeTest is DSTest {
    TokenBridge tokenBridge; 
    Vaults vaults; 
    Token token; 
    bytes32 tokenId  ="Token";
    CheatCodes cheats = CheatCodes(HEVM_ADDRESS);

    address constant user1 = 0xE0f5206BBD039e7b0592d8918820024e2a7437b9;
    address constant user2 = 0xAb5801a7D398351b8bE11C439e05C5B3259aeC9B;
    address self = address(this);

    event Enter(address indexed user, uint256 amount);
    event Exit(address indexed user, uint256 amount);

    function setUp() public {
        token = new Token();
        vaults = new Vaults(); 
        tokenBridge = new TokenBridge(address(vaults), tokenId, address(token));
        vaults.authorize(address(tokenBridge));
    }

    function testEnter() public {

        uint256 balance = token.balanceOf(self);
        uint256 amount = 1000; 
        token.approve(address(tokenBridge), amount);

        cheats.expectEmit(true, false, false, true);
        emit Enter(self, amount);
        tokenBridge.enter(self, amount);

        assertEq(token.balanceOf(self), balance-amount);
        assertEq(token.balanceOf(address(tokenBridge)), amount);
    }

    function testEnterAmountTooGreat() public {
        cheats.expectRevert(bytes("amount must be less than 2^255"));
        tokenBridge.enter(self, 2**255);
    }

    function testEnterTransferFailed() public {
        uint256 amount = 1000; 

        cheats.expectRevert(bytes("ERC20: insufficient allowance"));
        tokenBridge.enter(self, amount);
    }

    function testExit() public {
        uint256 balance = token.balanceOf(self);
        uint256 amount = 1000; 
        token.approve(address(tokenBridge), amount);
        tokenBridge.enter(self, amount);
        assertEq(token.balanceOf(self), balance-amount);
        assertEq(token.balanceOf(address(tokenBridge)), amount);

        cheats.expectEmit(true, false, false, true);
        emit Exit(self, amount);
        tokenBridge.exit(self, amount);
        assertEq(token.balanceOf(self), balance);
        assertEq(token.balanceOf(address(tokenBridge)), 0);
    }

    function testExitAmountTooGreat() public {
        cheats.expectRevert(bytes("amount must be less than 2^255"));
        tokenBridge.exit(self, 2**255);
    }

    function testExitTransferFailed() public {
        uint256 amount = 1000; 

        cheats.expectRevert(bytes("MathLib: add underflow"));
        tokenBridge.exit(self, amount);
    }


}