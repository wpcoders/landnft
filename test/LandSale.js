const { loadFixture } = require("@nomicfoundation/hardhat-network-helpers");
const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("CraftdefiSLands", async function () {
  async function deployTokenFixture() {
    const [owner, addr1, addr2] = await ethers.getSigners();

    const SACGramsFactory = await ethers.getContractFactory("SACGrams");
    const SACGramsToken = await SACGramsFactory.deploy();

    const xNorlaNFTFactory = await ethers.getContractFactory("xNorlaNFT");
    const xNorlaNFTToken = await xNorlaNFTFactory.deploy();

    const CraftdefiSLandsFactory = await ethers.getContractFactory(
      "contracts/CraftdefiSLands.sol:CraftdefiSLands"
    );
    const CraftdefiSLandsToken = await CraftdefiSLandsFactory.deploy();
    await CraftdefiSLandsToken.deployed();

    const lansSaleFactory = await ethers.getContractFactory("LandSale");
    const landSaleToken = await lansSaleFactory.deploy({
      gasLimit: 30000000,
    });
    await landSaleToken.deployed();

    await landSaleToken.setLandContract(CraftdefiSLandsToken.address);

    return {
      CraftdefiSLandsToken,
      landSaleToken,
      SACGramsToken,
      xNorlaNFTToken,
      owner,
      addr1,
      addr2,
    };
  }

  it("should return land contract address", async function () {
    const { CraftdefiSLandsToken, landSaleToken } = await loadFixture(
      deployTokenFixture
    );

    expect(await landSaleToken.land()).to.equal(CraftdefiSLandsToken.address);
  });

  it("should set sale price", async function () {
    const { landSaleToken } = await loadFixture(deployTokenFixture);

    await landSaleToken.setSalePrice(ethers.utils.parseEther("500").toString());

    const salePrice = ethers.utils.formatEther(await landSaleToken.PRICE());

    expect(salePrice).to.equal("500.0");
  });

  it("should set token contract", async function () {
    const { landSaleToken, SACGramsToken } = await loadFixture(
      deployTokenFixture
    );

    await landSaleToken.setToken(SACGramsToken.address);

    const tokenAddress = await landSaleToken.token();

    expect(tokenAddress).to.equal(SACGramsToken.address);
  });

  it("should set whitelist contract", async function () {
    const { landSaleToken, xNorlaNFTToken } = await loadFixture(
      deployTokenFixture
    );

    await landSaleToken.setToken(xNorlaNFTToken.address);

    const tokenAddress = await landSaleToken.token();

    expect(tokenAddress).to.equal(xNorlaNFTToken.address);
  });

  it("should set sale state", async function () {
    const { landSaleToken } = await loadFixture(deployTokenFixture);
    const setSaleTx = await landSaleToken.setSaleState([1, 2], true);
    await setSaleTx.wait();

    const saleState = await landSaleToken.saleFlag(2);

    expect(saleState).to.equal(true);
  });

  it("should set minter role", async function() {
    const { landSaleToken, CraftdefiSLandsToken } = await loadFixture(
      deployTokenFixture
    );
      console.log("landSaleToken.address", landSaleToken.address);
    const nGrantRoleTx = await CraftdefiSLandsToken.grantRole("0x9f2df0fed2c77648de5860a4cc508cd0818c85b8b8a1ab4ceeef8d981c8956a6", landSaleToken.address);
    await nGrantRoleTx.wait();

  });

  // it("should only enabled zone can be minted", async function () {
  //   const { landSaleToken, CraftdefiSLandsToken } = await loadFixture(
  //     deployTokenFixture
  //   );

  //   const newZoneTx = await CraftdefiSLandsToken.newZone("zone one");
  //   await newZoneTx.wait();

  //   const setSaleTx = await landSaleToken.setSaleState([1, 2], true);
  //   await setSaleTx.wait();

  //   const saleState = await landSaleToken.saleFlag(1);

  //   console.log("saleState", saleState);

  //   await landSaleToken.mintLand(0, 0, 2);
  // });

  // it("should set whitelist sale state", async function () {
  //   const { landSaleToken } = await loadFixture(deployTokenFixture);
  //   const setWhitelistTx = await landSaleToken.setWhitelistSaleState(
  //     [1, 2],
  //     true
  //   );

  //   await setWhitelistTx.wait();

  //   const isLandWhitelisted = await landSaleToken.whitelistSaleFlag(2);

  //   expect(isLandWhitelisted).to.equal(true);
  // });

  // it("should only enabled zone can be whitelist minted", async function() {
  //   const { landSaleToken } = await loadFixture(deployTokenFixture);

  //   const setWhitelistTx = await landSaleToken.setWhitelistSaleState([1], true);
  //   await setWhitelistTx.wait();

  //   const isLandWhitelisted = await landSaleToken.whitelistSaleFlag(1);

  //   console.log("isLandWhitelisted", isLandWhitelisted);

  //   await landSaleToken.whitelistMintLand(0, 0, 1);
  // });
});
