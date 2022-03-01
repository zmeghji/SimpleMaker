# #!/usr/bin/env bash
# This script liquidates an unsafe vault and buys some of the auctioned collateral
#Takes the following parameters:
#1. address of vault
#2. number of tokens to buy
#3. price to pay for tokens
#example: scripts/liquidate.sh 0x0823cA4422DfE3aC8e3cC66ceb7a1d4EA2eea519 5 3000000000000000000000000000

source ./.env1

VAULTS_ADDRESS=0x45295cd165c1490d68f515da8c3ceea7edc65185
TOKEN_ADDRESS=0x2eb2090a4380e03734fb217fa944fe1ecdd6a471
TOKENBRIDGE_ADDRESS=0xe10a7859045ab980640053bb27f0dd9d66e9bda7
DAI_ADDRESS=0xe222fb4af4314563282cfac7b4737623c0955ed8
DAIBRIDGE_ADDRESS=0x543bdd509e52b9fca186482ee5189d8393f85aa8
RATEUPDATER_ADDRESS=0x62c7c752cf4accb635cc1f58a28d3f0213149537
LIQUIDATOR_ADDRESS=0x76c690b1451a7e8f46aa240e2e89ee6272f5a729
AUCTIONEER_ADDRESS=0xecc2cfe07a142880f73ba819f33b020bcead0b27

TOTAL_TOKENS=10
NORMALIZED_DEBT_TOADD=30
TOKEN_ID=Token
TOKEN_ID_BYTES=$(cast --to-bytes32 <<< $(cast --from-ascii $TOKEN_ID))
TOKEN_PRICE=3000000000000000000000000000

echo "Update Stability fee for Token"
cast send $RATEUPDATER_ADDRESS "updateRate(bytes32 tokenId)" \
    $TOKEN_ID_BYTES --password $PASSWORD --keystore $KEYSTORE_PATH
echo Collateral Type VAULTS:  $(cast --abi-decode "CollateralType()(uint256,uint256,uint256)" $(cast call $VAULTS_ADDRESS "collateralTypes(bytes32 tokenId)" $TOKEN_ID_BYTES))
echo Vault: $(cast --abi-decode "Vault()(uint256,uint256)" $(cast call $VAULTS_ADDRESS "vaults(bytes32 tokenId, address user)" $TOKEN_ID_BYTES $1))
echo Collateral Type RATEUPDATER:  $(cast --abi-decode "CollateralType()(uint256,uint256)" $(cast call $RATEUPDATER_ADDRESS "collateralTypes(bytes32 tokenId)" $TOKEN_ID_BYTES))

echo "Liquidate Vault"
cast send $LIQUIDATOR_ADDRESS "liquidate(bytes32 tokenId, address vaultOwner)" \
    $TOKEN_ID_BYTES $1 --password $PASSWORD --keystore $KEYSTORE_PATH
echo Vault: $(cast --abi-decode "Vault()(uint256,uint256)" $(cast call $VAULTS_ADDRESS "vaults(bytes32 tokenId, address user)" $TOKEN_ID_BYTES $1))
echo auctioneer protocol token balance: $(cast --to-dec $(cast call $VAULTS_ADDRESS "tokenBalance(bytes32 tokenId, address user)" $TOKEN_ID_BYTES $1))
# echo $(cast --abi-decode "CollateralType()(address,uint256)" $(cast call $LIQUIDATOR_ADDRESS  "collateralTypes(bytes32 tokenId)" $TOKEN_ID_BYTES))

echo "SLEEP FOR 30 SECONDS"
sleep 30

NEXT_AUCTION_ID=$(cast --to-dec $(cast call $AUCTIONEER_ADDRESS  "nextAuctionId()"))
CURRENT_AUCTION_ID=$(($NEXT_AUCTION_ID-1))
echo Current Auction: $(cast --abi-decode "Auction()(uint256,uint256,uint256,address,uint256,uint256)" $(cast call $AUCTIONEER_ADDRESS "auctions(uint256 id)" $CURRENT_AUCTION_ID))

echo "Mark Auctioneer as a delegate of user"
cast send $VAULTS_ADDRESS "delegate(address delegatee)" \
    $AUCTIONEER_ADDRESS --password $PASSWORD --keystore $KEYSTORE_PATH

echo "Buy tokens from Auction"
# auctioneer.buy(0, totalTokens, price, user2);
cast send $AUCTIONEER_ADDRESS "buy(uint256 auctionId, uint256 maxCollateralToBuy, uint256 maxPrice, address receiver)" \
    $CURRENT_AUCTION_ID $2 $3 $ETH_FROM --password $PASSWORD --keystore $KEYSTORE_PATH
echo Current Auction: $(cast --abi-decode "Auction()(uint256,uint256,uint256,address,uint256,uint256)" $(cast call $AUCTIONEER_ADDRESS "auctions(uint256 id)" $CURRENT_AUCTION_ID))
echo buyer protocol token balance: $(cast --to-dec $(cast call $VAULTS_ADDRESS "tokenBalance(bytes32 tokenId, address user)" $TOKEN_ID_BYTES $ETH_FROM))