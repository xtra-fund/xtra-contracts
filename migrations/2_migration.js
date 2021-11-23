const fs = require("fs");
const path = require("path");
const { toWei, BN } = require("web3-utils");

// let initialBalances = JSON.parse(
//   fs.readFileSync("../snapshots/initialBalances.json")
// );

const isTestnet = true;
const testnetAddresses = false;
const mainnetAddress = false;

const XtraArtifact = artifacts.require("Xtra");
const SimpleERC20Artifact = artifacts.require("ERC20SimpleToken");
const AlloactionXtraTokenArtifact = artifacts.require("AlloactionXtraToken");
const PancakeFactoryArtifact = artifacts.require("IPancakeFactory");
const PancakeRouterArtifact = artifacts.require("IPancakeRouter01");

const wei = (n) => web3.utils.toWei(String(n), "ether");

const lpXtraTokenAmount = wei(1500000000);
const lpStableCoinAmount = wei(1500000);

const StartStakeDate = (Date.now() / 1000).toFixed(0);

let xtraAddress = "";
let psRouter = "0xD99D1c33F9fC3444f8101754aBC46c52416550D1";
let psFactory = "0x6725F303b657a9451d8BA641348b6761A6CC7a17";
let stableCoinAddress = "";
let allocationTokenAddress = "";

if (testnetAddresses) {
  xtraAddress = "0xaC4a1c96d1f8583ccaD3199A773C4042b2d4cEB3";
  psRouter = "0xD99D1c33F9fC3444f8101754aBC46c52416550D1";
  psFactory = "0x6725F303b657a9451d8BA641348b6761A6CC7a17";
  stableCoinAddress = "0x52f4916da41E1205b7Df478f3E74eEaD42e2725C";
}

if (mainnetAddress) {
  xtraAddress = "";
  psRouter = "0xD99D1c33F9fC3444f8101754aBC46c52416550D1";
  psFactory = "0x6725F303b657a9451d8BA641348b6761A6CC7a17";
  stableCoinAddress = "0xe9e7cea3dedca5984780bafc599bd69add087d56";
}

let Xtra, StableToken, AllocationToken;

module.exports = async function (deployer, network, accounts) {
  const toDistributeSale = {
    address: accounts[0],
  };

  /// BUSD
  if (stableCoinAddress) {
    StableToken = await SimpleERC20Artifact.at(stableCoinAddress);
  } else {
    await deployer.deploy(SimpleERC20Artifact, "BUST Stable Coin", "BUSD");
    StableToken = await SimpleERC20Artifact.deployed();
  }

  /// BUSD
  if (allocationTokenAddress) {
    AllocationToken = await AlloactionXtraTokenArtifact.at(
      allocationTokenAddress
    );
  } else {
    await deployer.deploy(
      AlloactionXtraTokenArtifact,
      "Allocation Xtra Token ",
      "AXTRA"
    );
    allocationToken = await AlloactionXtraTokenArtifact.deployed();
    allocationTokenAddress = allocationToken.address;
  }

  if (xtraAddress) {
    Xtra = await XtraArtifact.deployed();
  } else {
    await deployer.deploy(
      XtraArtifact,
      psFactory,
      StableToken.address,
      allocationTokenAddress
    );
    Xtra = await XtraArtifact.deployed();

    await Xtra.setStakingStartDate(StartStakeDate);

    await Xtra.distributeSale(toDistributeSale.address);
  }

  if (isTestnet) {
    /// PANCAKE SWAP PAIR
    if (!xtraAddress) {
      const PSFactory = await PancakeFactoryArtifact.at(psFactory);
      await PSFactory.createPair(Xtra.address, StableToken.address);

      const PSRouter = await PancakeRouterArtifact.at(psRouter);
      await Xtra.approve(psRouter, lpXtraTokenAmount);
      await StableToken.approve(psRouter, lpStableCoinAmount);
      await PSRouter.addLiquidity(
        Xtra.address,
        StableToken.address,
        lpXtraTokenAmount,
        lpStableCoinAmount,
        0,
        0,
        accounts[0],
        Math.floor(Date.now() / 1000) + 100
      );
    }
  }
};
