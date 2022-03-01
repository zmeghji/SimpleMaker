#!/usr/bin/env bash

#This script deploys all the contracts including a collateral token
#It also sets up the protocol to work with the collateral token

source ./.env

#collateral token id/name
TOKEN_ID=Token
TOKEN_ID_BYTES=$(cast --to-bytes32 <<< $(cast --from-ascii $TOKEN_ID))


#------------------------------------------DEPLOYMENTS------------------------------------------
#Deploy Vaults contract 
echo VAULTS_DEPLOYMENT
VAULTS_DEPLOYMENT=$(forge create Vaults \
    --keystore $KEYSTORE_PATH --password $PASSWORD)
echo $VAULTS_DEPLOYMENT
VAULTS_ADDRESS=$(sed -nE 's/.*Deployed to: //p' <<<$VAULTS_DEPLOYMENT)
echo $VAULTS_ADDRESS

#Deploy Collateral token 
echo TOKEN_DEPLOYMENT
TOKEN_DEPLOYMENT=$(forge create CollateralToken \
    --keystore $KEYSTORE_PATH --password $PASSWORD --constructor-args $TOKEN_ID TKN)
echo $TOKEN_DEPLOYMENT
TOKEN_ADDRESS=$(sed -nE 's/.*Deployed to: //p' <<<$TOKEN_DEPLOYMENT)
echo $TOKEN_ADDRESS

# #Deploy Dai token
echo DAI_DEPLOYMENT
DAI_DEPLOYMENT=$(forge create Dai \
    --keystore $KEYSTORE_PATH --password $PASSWORD )
echo $DAI_DEPLOYMENT
DAI_ADDRESS=$(sed -nE 's/.*Deployed to: //p' <<<$DAI_DEPLOYMENT)
echo $DAI_ADDRESS

# #Deploy Collateral Token Bridge
echo TOKENBRIDGE_DEPLOYMENT
TOKENBRIDGE_DEPLOYMENT=$(forge create TokenBridge \
    --keystore $KEYSTORE_PATH --password $PASSWORD --constructor-args $VAULTS_ADDRESS $TOKEN_ID_BYTES $TOKEN_ADDRESS)
echo $TOKENBRIDGE_DEPLOYMENT
TOKENBRIDGE_ADDRESS=$(sed -nE 's/.*Deployed to: //p' <<<$TOKENBRIDGE_DEPLOYMENT)
echo $TOKENBRIDGE_ADDRESS

#Deploy DaiBridge
# daiBridge = new DaiBridge(address(vaults), address(dai));
echo DAIBRIDGE_DEPLOYMENT
DAIBRIDGE_DEPLOYMENT=$(forge create DaiBridge \
    --keystore $KEYSTORE_PATH --password $PASSWORD --constructor-args $VAULTS_ADDRESS $DAI_ADDRESS)
echo $DAIBRIDGE_DEPLOYMENT
DAIBRIDGE_ADDRESS=$(sed -nE 's/.*Deployed to: //p' <<<$DAIBRIDGE_DEPLOYMENT)
echo $DAIBRIDGE_ADDRESS

#Deploy RateUpdater
#rateUpdater = new RateUpdater(address(vaults));
echo RATEUPDATER_DEPLOYMENT
RATEUPDATER_DEPLOYMENT=$(forge create RateUpdater \
    --keystore $KEYSTORE_PATH --password $PASSWORD --constructor-args $VAULTS_ADDRESS)
echo $RATEUPDATER_DEPLOYMENT
RATEUPDATER_ADDRESS=$(sed -nE 's/.*Deployed to: //p' <<<$RATEUPDATER_DEPLOYMENT)
echo $RATEUPDATER_ADDRESS

#Deploy Liquidator
#liquidator = new Liquidator(address(vaults));
echo LIQUIDATOR_DEPLOYMENT
LIQUIDATOR_DEPLOYMENT=$(forge create Liquidator \
    --keystore $KEYSTORE_PATH --password $PASSWORD --constructor-args $VAULTS_ADDRESS)
echo $LIQUIDATOR_DEPLOYMENT
LIQUIDATOR_ADDRESS=$(sed -nE 's/.*Deployed to: //p' <<<$LIQUIDATOR_DEPLOYMENT)
echo $LIQUIDATOR_ADDRESS

#Deploy Auctioneer
#auctioneer = new Auctioneer(address(vaults), tokenId);
echo AUCTIONEER_DEPLOYMENT
AUCTIONEER_DEPLOYMENT=$(forge create Auctioneer \
    --keystore $KEYSTORE_PATH --password $PASSWORD --constructor-args $VAULTS_ADDRESS $TOKEN_ID_BYTES)
echo $AUCTIONEER_DEPLOYMENT
AUCTIONEER_ADDRESS=$(sed -nE 's/.*Deployed to: //p' <<<$AUCTIONEER_DEPLOYMENT)
echo $AUCTIONEER_ADDRESS

#------------------------------------------AUTHORIZE------------------------------------------
echo AUTHORIZE 

#Vaults authorizes TokenBridge and RateUpdater
cast send $VAULTS_ADDRESS "authorize(address user)" \
    $TOKENBRIDGE_ADDRESS --password $PASSWORD --keystore $KEYSTORE_PATH
cast send $VAULTS_ADDRESS "authorize(address user)" \
    $RATEUPDATER_ADDRESS --password $PASSWORD --keystore $KEYSTORE_PATH

#Dai authorizes DaiBridge
cast send $DAI_ADDRESS "authorize(address user)" \
    $DAIBRIDGE_ADDRESS --password $PASSWORD --keystore $KEYSTORE_PATH

#Auctioneer authorizes Liquidator
cast send $AUCTIONEER_ADDRESS "authorize(address user)" \
    $LIQUIDATOR_ADDRESS --password $PASSWORD --keystore $KEYSTORE_PATH

#------------------------------------------SETUP------------------------------------------

#3*10**27
TOKEN_PRICE=3000000000000000000000000000

#10**27 +1
TOKEN_STABILITY_FEE=1000000000001101011100000001

#10**27
LIQUIDATION_FEE=1000000000000000000

#60*60*24
MAX_AUCTION_DURATION=86400

#10**27
AUCTION_PRICE_MULTIPLIER=1000000000000000000000000001


#Setup Vaults
echo SETUP VAULTS
cast send $VAULTS_ADDRESS "addCollateralType(bytes32 tokenId)" \
    $TOKEN_ID_BYTES --password $PASSWORD --keystore $KEYSTORE_PATH
cast send $VAULTS_ADDRESS "updatePrice(bytes32 tokenId, uint newPrice)" \
    $TOKEN_ID_BYTES $TOKEN_PRICE --password $PASSWORD --keystore $KEYSTORE_PATH

#Setup RateUpdater
echo SETUP RATEUPDATER 
cast send $RATEUPDATER_ADDRESS "addCollateralType(bytes32 tokenId)" \
    $TOKEN_ID_BYTES --password $PASSWORD --keystore $KEYSTORE_PATH
fee=$(cast --to-bytes32 <<< $(cast --from-ascii fee))
cast send $RATEUPDATER_ADDRESS "update(bytes32 tokenId, bytes32 field, uint256 newValue)" \
    $TOKEN_ID_BYTES $fee $TOKEN_STABILITY_FEE --password $PASSWORD --keystore $KEYSTORE_PATH

#Setup Liquidator
echo SETUP LIQUIDATOR
auctioneer=$(cast --to-bytes32 <<< $(cast --from-ascii auctioneer))
penalty=$(cast --to-bytes32 <<< $(cast --from-ascii penalty))
cast send $LIQUIDATOR_ADDRESS "update(bytes32 tokenId, bytes32 field, address newValue)" \
    $TOKEN_ID_BYTES $auctioneer $AUCTIONEER_ADDRESS --password $PASSWORD --keystore $KEYSTORE_PATH
cast send $LIQUIDATOR_ADDRESS "update(bytes32 tokenId, bytes32 field, uint256 newValue)" \
    $TOKEN_ID_BYTES $penalty $LIQUIDATION_FEE --password $PASSWORD --keystore $KEYSTORE_PATH

#Setup Auctioneer
echo SETUP AUCTIONEER
maxDuration=$(cast --to-bytes32 <<< $(cast --from-ascii maxDuration))
tau=$(cast --to-bytes32 <<< $(cast --from-ascii tau))
priceMultiplier=$(cast --to-bytes32 <<< $(cast --from-ascii priceMultiplier))
cast send $AUCTIONEER_ADDRESS "update(bytes32 field, uint256 newValue)" \
    $maxDuration $MAX_AUCTION_DURATION --password $PASSWORD --keystore $KEYSTORE_PATH
cast send $AUCTIONEER_ADDRESS "update(bytes32 field, uint256 newValue)" \
    $tau $MAX_AUCTION_DURATION --password $PASSWORD --keystore $KEYSTORE_PATH
cast send $AUCTIONEER_ADDRESS "update(bytes32 field, uint256 newValue)" \
    $priceMultiplier $AUCTION_PRICE_MULTIPLIER --password $PASSWORD --keystore $KEYSTORE_PATH