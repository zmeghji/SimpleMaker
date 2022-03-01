#!/usr/bin/env bash

#This script will open and close a vault in the simple maker protocol
source ./.env1

VAULTS_ADDRESS=0x45295cd165c1490d68f515da8c3ceea7edc65185
TOKEN_ADDRESS=0x2eb2090a4380e03734fb217fa944fe1ecdd6a471
TOKENBRIDGE_ADDRESS=0xe10a7859045ab980640053bb27f0dd9d66e9bda7
DAI_ADDRESS=0xe222fb4af4314563282cfac7b4737623c0955ed8
DAIBRIDGE_ADDRESS=0x543bdd509e52b9fca186482ee5189d8393f85aa8

TOTAL_TOKENS=10
NORMALIZED_DEBT_TOADD=29
TOKEN_ID=Token
TOKEN_ID_BYTES=$(cast --to-bytes32 <<< $(cast --from-ascii $TOKEN_ID))
TOKEN_PRICE=3000000000000000000000000000

echo "Get collateral tokens using faucet"
cast send $TOKEN_ADDRESS "faucet()" --password $PASSWORD --keystore $KEYSTORE_PATH
echo token balance: $(cast --to-dec $(cast call $TOKEN_ADDRESS "balanceOf(address account)" $ETH_FROM))

echo "Approve the tokenBridge to transfer user's tokens"
cast send $TOKEN_ADDRESS "approve(address spender, uint256 amount)" \
    $TOKENBRIDGE_ADDRESS $TOTAL_TOKENS --password $PASSWORD --keystore $KEYSTORE_PATH

echo "Add tokens to protocol using TokenBridge"
cast send $TOKENBRIDGE_ADDRESS "enter(address user, uint256 amount)" \
    $ETH_FROM $TOTAL_TOKENS --password $PASSWORD --keystore $KEYSTORE_PATH
echo protocol token balance: $(cast --to-dec $(cast call $VAULTS_ADDRESS "tokenBalance(bytes32 tokenId, address user)" $TOKEN_ID_BYTES $ETH_FROM))
echo token balance: $(cast --to-dec $(cast call $TOKEN_ADDRESS "balanceOf(address account)" $ETH_FROM))

echo "Opening Vault"
cast send $VAULTS_ADDRESS \
    "modifyVault(bytes32 tokenId, address vaultOwner, address collateralProvider, address daiReceiver, int collateralToAdd, int normalizedDebtToAdd)" \
    $TOKEN_ID_BYTES $ETH_FROM $ETH_FROM $ETH_FROM $TOTAL_TOKENS $NORMALIZED_DEBT_TOADD --password $PASSWORD --keystore $KEYSTORE_PATH
echo protocol token balance: $(cast --to-dec $(cast call $VAULTS_ADDRESS "tokenBalance(bytes32 tokenId, address user)" $TOKEN_ID_BYTES $ETH_FROM))
echo protocol dai balance: $(cast --to-dec $(cast call $VAULTS_ADDRESS "daiBalance(address user)" $ETH_FROM))
echo dai balance: $(cast --to-dec $(cast call $DAI_ADDRESS "balanceOf(address account)" $ETH_FROM))

echo "Delegate daiBridge to act on user's behalf"
cast send $VAULTS_ADDRESS "delegate(address delegatee)" \
    $DAIBRIDGE_ADDRESS --password $PASSWORD --keystore $KEYSTORE_PATH

echo "Minting Dai for user"
cast send $DAIBRIDGE_ADDRESS "exit(address user, uint256 amount)" \
    $ETH_FROM $NORMALIZED_DEBT_TOADD --password $PASSWORD --keystore $KEYSTORE_PATH
echo protocol dai balance: $(cast --to-dec $(cast call $VAULTS_ADDRESS "daiBalance(address user)" $ETH_FROM))
echo dai balance: $(cast --to-dec $(cast call $DAI_ADDRESS "balanceOf(address account)" $ETH_FROM))


echo "Approve DaiBridge to transfer user's dai"
cast send $DAI_ADDRESS "approve(address spender, uint256 amount)" \
    $DAIBRIDGE_ADDRESS $NORMALIZED_DEBT_TOADD --password $PASSWORD --keystore $KEYSTORE_PATH

echo "Send Dai back to protocol"
cast send $DAIBRIDGE_ADDRESS "enter(address user, uint256 amount)" \
    $ETH_FROM $NORMALIZED_DEBT_TOADD --password $PASSWORD --keystore $KEYSTORE_PATH
echo protocol dai balance: $(cast --to-dec $(cast call $VAULTS_ADDRESS "daiBalance(address user)" $ETH_FROM))
echo dai balance: $(cast --to-dec $(cast call $DAI_ADDRESS "balanceOf(address account)" $ETH_FROM))

echo "Close the Vault"
cast send $VAULTS_ADDRESS  --password $PASSWORD --keystore $KEYSTORE_PATH   \
    "modifyVault(bytes32 tokenId, address vaultOwner, address collateralProvider, address daiReceiver, int collateralToAdd, int normalizedDebtToAdd)" \
    $TOKEN_ID_BYTES $ETH_FROM $ETH_FROM $ETH_FROM $(sed  's/.*0x//' <<< $(cast --to-int256 -- -$TOTAL_TOKENS)) $(sed  's/.*0x//' <<< $(cast --to-int256 -- -$NORMALIZED_DEBT_TOADD))

echo protocol token balance: $(cast --to-dec $(cast call $VAULTS_ADDRESS "tokenBalance(bytes32 tokenId, address user)" $TOKEN_ID_BYTES $ETH_FROM))
echo protocol dai balance: $(cast --to-dec $(cast call $VAULTS_ADDRESS "daiBalance(address user)" $ETH_FROM))

echo "Withdraw tokens from protocol"
cast send $TOKENBRIDGE_ADDRESS "exit(address user, uint256 amount)" \
    $ETH_FROM $TOTAL_TOKENS --password $PASSWORD --keystore $KEYSTORE_PATH
echo protocol token balance: $(cast --to-dec $(cast call $VAULTS_ADDRESS "tokenBalance(bytes32 tokenId, address user)" $TOKEN_ID_BYTES $ETH_FROM))
echo token balance: $(cast --to-dec $(cast call $TOKEN_ADDRESS "balanceOf(address account)" $ETH_FROM))