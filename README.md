# Simple Maker

Simple Maker is a simplified version of the Maker protocol built using Foundry. It supports the collateralization of tokens, vault manipulation, borrowing of Dai, stability fees and collateral auctions. It is highly inspired by the [DSS code base of the Maker Protocol](https://github.com/makerdao/dss/tree/master/src). It takes a different approach with coding standards including the use of inheritance and more intuitive naming. It currently lacks many features of the full Maker protocol including governance, debt auctions, surplus auctions and the use of oracles.

## Deployed Contracts (Kovan) 💎
- [Vaults](https://kovan.etherscan.io/address/0x45295cd165c1490d68f515da8c3ceea7edc65185): Stores the state of the protocol including token balances, dai balances and vault details.
- [Token](https://kovan.etherscan.io/address/0x2eb2090a4380e03734fb217fa944fe1ecdd6a471): A simple ERC-20 token which can be used as collateral within the protocol. It has a faucet method to allow any user to mint a small number of tokens.
- [Token Bridge](https://kovan.etherscan.io/address/0xe10a7859045ab980640053bb27f0dd9d66e9bda7): Allows tokens from **Token contract** to be deposited into and withdrawn from the Maker Protocol
- [Dai](https://kovan.etherscan.io/address/0xe222fb4af4314563282cfac7b4737623c0955ed8): The Dai (stablecoin) token contract.
- [Dai Bridge](https://kovan.etherscan.io/address/0x543bdd509e52b9fca186482ee5189d8393f85aa8): Allows Dai tokens to be deposited into and withdrawn from the Maker Protocol
- [Rate Updater](https://kovan.etherscan.io/address/0x62c7c752cf4accb635cc1f58a28d3f0213149537): Updates stability fees for different collateral types within the Vaults contract
- [Liquidator](https://kovan.etherscan.io/address/0x76c690b1451a7e8f46aa240e2e89ee6272f5a729): Liquidates vaults with an unsafe debt-to-collateral ratio, and triggers a collateral auction for them
- [Auctioneer](https://kovan.etherscan.io/address/0xecc2cfe07a142880f73ba819f33b020bcead0b27): Handles the logic for collateral auctions, including starting/restarting the auctions, purchasing collateral from auctions and determining the auction price of collateral.

## How To Run ▶️
1. [Install Foundry](https://onbjerg.github.io/foundry-book/getting-started/installation.html)
2. Clone repo with recursive option
   ```
   git clone --recursive https://github.com/zmeghji/SimpleMaker.git
   ```
3. Cd into main directory
   ```
   cd SimpleMaker/
   ```
4. Run Tests
   ```
   forge test
   ```
5. If you want to deploy the contracts yourself, copy the example.env file, rename it to .env, and fill it with your account/environment details. You can then run the following script:
   ```
   ./scripts/deploy.sh
   ```
6. To open and close a vault, you can use the following script. You will have to copy the example.env file, rename it to .env1 and fill it with your account details. If you deployed your own contracts in step 5, you'll also need to update the addresses of the contracts near the top of the script.
   ```
   ./scripts/openAndCloseVault.sh
   ```
7. If a vault ends up having an unsafe debt to collateral ratio, you can liquidate it and also buy some of the collateral in the auction using the following script. As with step 6, you'll have to add the .env1 file and fill it with your account details. Also if you've deployed your own contracts in step 5, then you'll need to change the contract addresses near the top of the script.
   ```
   ./scripts/liquidate.sh <vaultAddress> <amountOfCollateralToBuy> <priceToBuyAt>
   ```

## Tools, Languages & Frameworks Used 🛠️
- Solidity
- Foundry (forge and cast)
- OpenZeppelin
- ds-test
- GitHub Actions
- Bash/Shell 