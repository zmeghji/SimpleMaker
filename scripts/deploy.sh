#!/usr/bin/env bash
source ./.env

#collateral token id/name
TOKEN_ID=Token
TOKEN_ID_BYTES=$(cast --to-bytes32 <<< $(cast --from-ascii $TOKEN_ID))


#------------------------------------------DEPLOYMENTS------------------------------------------
#Deploy Vaults contract 
echo VAULTS_DEPLOYMENT
VAULTS_DEPLOYMENT=$(forge create Vaults --keystore $KEYSTORE_PATH --password $PASSWORD)
echo $VAULTS_DEPLOYMENT
VAULTS_ADDRESS=$(sed -nE 's/.*Deployed to: //p' <<<$VAULTS_DEPLOYMENT)
echo $VAULTS_ADDRESS

#Deploy Collateral token 
echo TOKEN_DEPLOYMENT
TOKEN_DEPLOYMENT=$(forge create CollateralToken --keystore $KEYSTORE_PATH --password $PASSWORD --constructor-args $TOKEN_ID TKN)
echo $TOKEN_DEPLOYMENT
TOKEN_ADDRESS=$(sed -nE 's/.*Deployed to: //p' <<<$TOKEN_DEPLOYMENT)
echo $TOKEN_ADDRESS

# #Deploy Dai token
echo DAI_DEPLOYMENT
DAI_DEPLOYMENT=$(forge create Dai --keystore $KEYSTORE_PATH --password $PASSWORD )
echo $DAI_DEPLOYMENT
DAI_ADDRESS=$(sed -nE 's/.*Deployed to: //p' <<<$DAI_DEPLOYMENT)
echo $DAI_ADDRESS

# #Deploy Collateral Token Bridge
echo TOKENBRIDGE_DEPLOYMENT
TOKENBRIDGE_DEPLOYMENT=$(forge create TokenBridge --keystore $KEYSTORE_PATH --password $PASSWORD --constructor-args $VAULTS_ADDRESS $TOKEN_ID_BYTES $TOKEN_ADDRESS)
echo $TOKENBRIDGE_DEPLOYMENT
TOKENBRIDGE_ADDRESS=$(sed -nE 's/.*Deployed to: //p' <<<$TOKENBRIDGE_DEPLOYMENT)
echo $TOKENBRIDGE_ADDRESS

#Deploy DaiBridge
# daiBridge = new DaiBridge(address(vaults), address(dai));
echo DAIBRIDGE_DEPLOYMENT
DAIBRIDGE_DEPLOYMENT=$(forge create DaiBridge --keystore $KEYSTORE_PATH --password $PASSWORD --constructor-args $VAULTS_ADDRESS $DAI_ADDRESS)
echo $DAIBRIDGE_DEPLOYMENT
DAIBRIDGE_ADDRESS=$(sed -nE 's/.*Deployed to: //p' <<<$DAIBRIDGE_DEPLOYMENT)
echo $DAIBRIDGE_ADDRESS

#Deploy RateUpdater
#rateUpdater = new RateUpdater(address(vaults));
echo RATEUPDATER_DEPLOYMENT
RATEUPDATER_DEPLOYMENT=$(forge create RateUpdater --keystore $KEYSTORE_PATH --password $PASSWORD --constructor-args $VAULTS_ADDRESS)
echo $RATEUPDATER_DEPLOYMENT
RATEUPDATER_ADDRESS=$(sed -nE 's/.*Deployed to: //p' <<<$RATEUPDATER_DEPLOYMENT)
echo $RATEUPDATER_ADDRESS

#Deploy Liquidator
#liquidator = new Liquidator(address(vaults));
echo LIQUIDATOR_DEPLOYMENT
LIQUIDATOR_DEPLOYMENT=$(forge create Liquidator --keystore $KEYSTORE_PATH --password $PASSWORD --constructor-args $VAULTS_ADDRESS)
echo $LIQUIDATOR_DEPLOYMENT
LIQUIDATOR_ADDRESS=$(sed -nE 's/.*Deployed to: //p' <<<$LIQUIDATOR_DEPLOYMENT)
echo $LIQUIDATOR_ADDRESS

#Deploy Auctioneer
#auctioneer = new Auctioneer(address(vaults), tokenId);
echo AUCTIONEER_DEPLOYMENT
AUCTIONEER_DEPLOYMENT=$(forge create Auctioneer --keystore $KEYSTORE_PATH --password $PASSWORD --constructor-args $VAULTS_ADDRESS $TOKEN_ID_BYTES)
echo $AUCTIONEER_DEPLOYMENT
AUCTIONEER_ADDRESS=$(sed -nE 's/.*Deployed to: //p' <<<$AUCTIONEER_DEPLOYMENT)
echo $AUCTIONEER_ADDRESS

#------------------------------------------AUTHORIZE------------------------------------------
echo AUTHORIZE 

#Vaults authorizes TokenBridge and RateUpdater
cast send $VAULTS_ADDRESS "authorize(address user)" $TOKENBRIDGE_ADDRESS --password $PASSWORD --keystore $KEYSTORE_PATH
cast send $VAULTS_ADDRESS "authorize(address user)" $RATEUPDATER_ADDRESS --password $PASSWORD --keystore $KEYSTORE_PATH

#Dai authorizes DaiBridge
cast send $DAI_ADDRESS "authorize(address user)" $DAIBRIDGE_ADDRESS --password $PASSWORD --keystore $KEYSTORE_PATH

#Auctioneer authorizes Liquidator
cast send $AUCTIONEER_ADDRESS "authorize(address user)" $LIQUIDATOR_ADDRESS --password $PASSWORD --keystore $KEYSTORE_PATH

#------------------------------------------SETUP------------------------------------------




# ETH_RPC_URL=$KOVAN_RPC_URL seth call 0x28a717d0419c4207bac8acb658ad6b90124a5044 "randomResult()"

# ETH_RPC_URL=$ETH_RPC_URL seth call 0xda9ddeea117a175af7d198267827c2152f7bb947 "name()"
# ETH_RPC_URL=$ETH_RPC_URL seth call 0xd39ff3e4bfa11bf2e6df9409079886edc9a4712b "tokenId()"

# seth send $VAULTS_ADDRESS "authorize(address user)" 