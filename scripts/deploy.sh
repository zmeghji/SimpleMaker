#!/usr/bin/env bash
source ./.env

VAULTS_DEPLOYMENT=$(forge create Vaults --keystore $KEYSTORE_PATH --password $PASSWORD)
echo $VAULTS_DEPLOYMENT
VAULTS_ADDRESS=$(sed -nE 's/.*Deployed to: //p' <<<$VAULTS_DEPLOYMENT)
echo $VAULTS_ADDRESS
