// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// You can also run a script with `npx hardhat run <script>`. If you do that, Hardhat
// will compile your contracts, add the Hardhat Runtime Environment's members to the
// global scope, and execute the script.
const hre = require("hardhat");

async function main() {
  const CraftdefiSLands = await hre.ethers.getContractFactory(
    "contracts/CraftdefiSLands.sol:CraftdefiSLands"
  );
  const LandSale = await hre.ethers.getContractFactory("LandSale");
  const SACGrams = await hre.ethers.getContractFactory("SACGrams");
  const xNorlaNFT = await hre.ethers.getContractFactory("xNorlaNFT");

  console.log('CraftdefiSLands deploying');

  const DeployedCraftdefiSLands = await CraftdefiSLands.deploy();

  await DeployedCraftdefiSLands.deployed();

  console.log(`CraftdefiSLands deployed at ${DeployedCraftdefiSLands.address}`);

  console.log('LandSale deploying');
  const DeployedLandSale = await LandSale.deploy();

  await DeployedLandSale.deployed();
  console.log(`LandSale deployed at ${DeployedCraftdefiSLands.address}`);

  console.log('SACGrams deploying');
  const DeployedSACGrams = await SACGrams.deploy();

  await DeployedSACGrams.deployed();
  console.log(`SACGrams deployed at ${DeployedCraftdefiSLands.address}`);

  console.log('xNorlaNFT deploying');
  const DeployedxNorlaNFT = await xNorlaNFT.deploy();

  await DeployedxNorlaNFT.deployed();
  console.log(`xNorlaNFT deployed at ${DeployedCraftdefiSLands.address}`);

  console.log(
    `--- \n CraftdefiSLands deployed to ${DeployedCraftdefiSLands.address} \n
     LandSale deployed to ${DeployedLandSale.address} \n
     SACGrams deployed to ${DeployedSACGrams.address} \n
     DeployedxNorlaNFT deployed to ${DeployedxNorlaNFT.address}
     `
  );
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
