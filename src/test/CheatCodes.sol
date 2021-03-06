// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;

interface CheatCodes {
  function prank(address) external;
  function startPrank(address) external;
  function stopPrank() external;
  function expectRevert(bytes calldata) external;
  function expectEmit(bool, bool, bool, bool) external;
  function warp(uint256) external;
}