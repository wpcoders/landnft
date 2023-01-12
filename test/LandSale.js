const { loadFixture } = require("@nomicfoundation/hardhat-network-helpers");
const { expect } = require("chai");
const { ethers, upgrades } = require("hardhat");

describe("CraftdefiSLands", async function () {
  async function deployTokenFixture() {
    const [owner, addr1, addr2, addr3, addr4] = await ethers.getSigners();

    const BUSDFactory = await ethers.getContractFactory("BEP20Token");
    const BUSDToken = await BUSDFactory.deploy();

    const xNorlaNFTFactory = await ethers.getContractFactory("xNorlaNFT");
    const xNorlaNFTToken = await xNorlaNFTFactory.deploy();

    const xNorlaNFTProxy = await upgrades.deployProxy(xNorlaNFTFactory);

    const CraftdefiSLandsFactory = await ethers.getContractFactory(
      "contracts/CraftdefiSLands.sol:CraftdefiSLands"
    );

    const CraftdefiSLandsToken = await CraftdefiSLandsFactory.deploy();
    await CraftdefiSLandsToken.deployed();

    const proxyContract = await upgrades.deployProxy(CraftdefiSLandsFactory);

    const lansSaleFactory = await ethers.getContractFactory("LandSale");
    const landSaleToken = await lansSaleFactory.deploy({
      gasLimit: 30000000,
    });
    await landSaleToken.deployed();

    await landSaleToken.setLandContract(proxyContract.address);
    await landSaleToken.setWhitelistContract(xNorlaNFTProxy.address);

    return {
      CraftdefiSLandsToken,
      landSaleToken,
      xNorlaNFTToken,
      proxyContract,
      xNorlaNFTProxy,
      BUSDToken,
      owner,
      addr1,
      addr2,
      addr3,
      addr4,
    };
  }

  it("should return land contract address", async function () {
    const { proxyContract, landSaleToken } = await loadFixture(
      deployTokenFixture
    );

    expect(await landSaleToken.land()).to.equal(proxyContract.address);
  });

  it("should set sale price", async function () {
    const { landSaleToken } = await loadFixture(deployTokenFixture);

    await landSaleToken.setSalePrice(ethers.utils.parseEther("500").toString());

    const salePrice = ethers.utils.formatEther(await landSaleToken.PRICE());

    expect(salePrice).to.equal("500.0");
  });

  it("should set token contract", async function () {
    const { landSaleToken, xNorlaNFTProxy } = await loadFixture(
      deployTokenFixture
    );

    await landSaleToken.setToken(xNorlaNFTProxy.address);

    const tokenAddress = await landSaleToken.token();

    expect(tokenAddress).to.equal(xNorlaNFTProxy.address);
  });

  it("should set whitelist contract", async function () {
    const { landSaleToken, xNorlaNFTProxy } = await loadFixture(
      deployTokenFixture
    );

    await landSaleToken.setToken(xNorlaNFTProxy.address);

    const tokenAddress = await landSaleToken.token();

    expect(tokenAddress).to.equal(xNorlaNFTProxy.address);
  });

  it("should set sale state", async function () {
    const { landSaleToken } = await loadFixture(deployTokenFixture);
    const setSaleTx = await landSaleToken.setSaleState([1, 2], true);
    await setSaleTx.wait();

    const saleState = await landSaleToken.saleFlag(2);

    expect(saleState).to.equal(true);
  });

  it("should set minter role", async function () {
    const { landSaleToken, proxyContract } = await loadFixture(
      deployTokenFixture
    );

    const nGrantRoleTx = await proxyContract.grantRole(
      "0x9f2df0fed2c77648de5860a4cc508cd0818c85b8b8a1ab4ceeef8d981c8956a6",
      landSaleToken.address
    );

    await nGrantRoleTx.wait();
  });

  it("should only enabled zone can be minted", async function () {
    const { landSaleToken, proxyContract, addr1 } = await loadFixture(
      deployTokenFixture
    );

    const newZoneTx = await proxyContract.newZone("zone one");
    await newZoneTx.wait();

    const setSaleTx = await landSaleToken.setSaleState([1, 2], true);
    await setSaleTx.wait();

    await proxyContract.safeMint(addr1.address, 0, 0, 1);
  });

  it("should set Cool Down Period.", async function () {
    const { landSaleToken } = await loadFixture(deployTokenFixture);

    await landSaleToken.setCooldownPeriod(1200);

    const cooldownPeriod = (await landSaleToken.cooldownPeriod()).toNumber();

    expect(cooldownPeriod).to.equal(1200);
  });

  it("should not mint another NFT within Cool Down Period.", async function () {
    const { landSaleToken, proxyContract, xNorlaNFTProxy, owner, BUSDToken } =
      await loadFixture(deployTokenFixture);

    const nGrantRoleTx = await proxyContract.grantRole(
      "0x9f2df0fed2c77648de5860a4cc508cd0818c85b8b8a1ab4ceeef8d981c8956a6",
      landSaleToken.address
    );
    await nGrantRoleTx.wait();

    const sacTx = await landSaleToken.setToken(BUSDToken.address);
    await sacTx.wait();

    const allowanceTx = await BUSDToken.approve(
      landSaleToken.address,
      "100000000000000000000"
    );
    await allowanceTx.wait();

    const newZoneTx = await proxyContract.newZone("zone one");
    await newZoneTx.wait();

    const setSaleTx = await landSaleToken.setSaleState([1], true);
    await setSaleTx.wait();

    const setCoolTx = await landSaleToken.setCooldownPeriod(1200);
    await setCoolTx.wait();

    const ttx1 = await landSaleToken.mintLand(0, 1, 1, {
      from: owner.address,
    });
    await ttx1.wait();

    await expect(
      landSaleToken.mintLand(0, 2, 1, {
        from: owner.address,
      })
    ).to.be.revertedWith(
      "Wait till the cooldown Periodexpires to buy new Land"
    );
  });

  it("should set whitelist sale state", async function () {
    const { landSaleToken } = await loadFixture(deployTokenFixture);
    const setWhitelistTx = await landSaleToken.setWhitelistSaleState(
      [1, 2],
      true
    );

    await setWhitelistTx.wait();

    const isLandWhitelisted = await landSaleToken.whitelistSaleFlag(2);

    expect(isLandWhitelisted).to.equal(true);
  });

  it("should only enabled zone can be whitelist minted", async function () {
    const { landSaleToken, proxyContract, BUSDToken, owner, xNorlaNFTProxy } =
      await loadFixture(deployTokenFixture);

    const nGrantRoleTx = await proxyContract.grantRole(
      "0x9f2df0fed2c77648de5860a4cc508cd0818c85b8b8a1ab4ceeef8d981c8956a6",
      landSaleToken.address
    );
    await nGrantRoleTx.wait();

    const sacTx = await landSaleToken.setToken(BUSDToken.address);
    await sacTx.wait();

    const allowanceTx = await BUSDToken.approve(
      landSaleToken.address,
      "1000000000000000000"
    );
    await allowanceTx.wait();

    const newZoneTx = await proxyContract.newZone("zone two");
    await newZoneTx.wait();

    const newZoneTx2 = await proxyContract.newZone("zone three");
    await newZoneTx2.wait();

    const setWhitelistTx = await landSaleToken.setWhitelistSaleState(
      [1, 2],
      true
    );
    await setWhitelistTx.wait();

    const mintTx = await xNorlaNFTProxy.safeMint(owner.address, 3);
    await mintTx.wait();

    const finalMintTx = await landSaleToken.whitelistMintLand(1, 0, 0, 1, {
      from: owner.address,
    });
    await finalMintTx.wait();

    const isWhiteListClaimed = await landSaleToken.whitelistClaimed(1);

    expect(isWhiteListClaimed).to.equal(true);
  });

  it("should set approve tokens", async function () {
    const { landSaleToken, BUSDToken, owner } = await loadFixture(
      deployTokenFixture
    );

    await BUSDToken.approve(
      landSaleToken.address,
      ethers.utils.parseEther("500")
    );

    const allowance = Number(
      ethers.utils
        .formatEther(
          await BUSDToken.allowance(owner.address, landSaleToken.address)
        )
        .toString()
    );

    expect(allowance).to.equal(500);
  });

  it("should ignore cooldown period for whitelist mint", async function () {
    const { landSaleToken, proxyContract, BUSDToken, owner, xNorlaNFTProxy } =
      await loadFixture(deployTokenFixture);

    const setCoolTx = await landSaleToken.setCooldownPeriod(1200);
    await setCoolTx.wait();

    const nGrantRoleTx = await proxyContract.grantRole(
      "0x9f2df0fed2c77648de5860a4cc508cd0818c85b8b8a1ab4ceeef8d981c8956a6",
      landSaleToken.address
    );
    await nGrantRoleTx.wait();

    const sacTx = await landSaleToken.setToken(BUSDToken.address);
    await sacTx.wait();

    const allowanceTx = await BUSDToken.approve(
      landSaleToken.address,
      "1000000000000000000"
    );
    await allowanceTx.wait();

    const newZoneTx = await proxyContract.newZone("zone two");
    await newZoneTx.wait();

    const newZoneTx2 = await proxyContract.newZone("zone three");
    await newZoneTx2.wait();

    const setWhitelistTx = await landSaleToken.setWhitelistSaleState(
      [1, 2],
      true
    );
    await setWhitelistTx.wait();

    const mintTx = await xNorlaNFTProxy.safeMint(owner.address, 3);
    await mintTx.wait();

    const firstMintTx = await landSaleToken.whitelistMintLand(1, 0, 0, 1, {
      from: owner.address,
    });
    await firstMintTx.wait();

    const finalMintTx = await landSaleToken.whitelistMintLand(2, 0, 1, 1, {
      from: owner.address,
    });
    await finalMintTx.wait();

    const isWhiteListClaimedF = await landSaleToken.whitelistClaimed(1);
    const isWhiteListClaimed = await landSaleToken.whitelistClaimed(2);

    expect(isWhiteListClaimed === isWhiteListClaimedF).to.equal(true);
  });
});
