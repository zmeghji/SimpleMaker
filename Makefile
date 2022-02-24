# include .env file and export its env vars
# (-include to ignore error if it does not exist)
-include .env


# Deployment helper (Note must have PRIVATE_KEY environment variable set )
# deploy :; forge create Vaults --keystore /home/zmeghji/.ethereum/keystore
deploy :; forge create Vaults --keystore ${KEYSTORE_PATH}

