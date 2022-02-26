# include .env file and export its env vars
# (-include to ignore error if it does not exist)
-include .env


# Deployment helper (Note must have PRIVATE_KEY environment variable set )
# deploy :; ./scrips/deploy.sh
deploy :; ./deploy.sh

# deploy :
# 	forge create Vaults --keystore ${KEYSTORE_PATH} --password ${PASSWORD}
