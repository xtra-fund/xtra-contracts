const fs = require("fs");
const path = require("path");
const { toWei, BN } = require("web3-utils");

const AlloactionXtraTokenArtifact = artifacts.require("AlloactionXtraToken");

// let initialBalances = JSON.parse(
//   fs.readFileSync("../snapshots/initialBalances.json")
// );

const testnetAddresses = true;
const mainnetAddress = false;

const XtraArtifact = artifacts.require("Xtra");

const wei = (n) => web3.utils.toWei(String(n), "ether");

const StartStakeDate = (Date.now() / 1000).toFixed(0);

let xtraAddress = "0x622A42eeC118304Eeb76Bf1Ac0dc08023BdF61f1";
let allocationTokenAddress = "0x622A42eeC118304Eeb76Bf1Ac0dc08023BdF61f1";

if (testnetAddresses) {
  xtraAddress = "0x622A42eeC118304Eeb76Bf1Ac0dc08023BdF61f1";
  allocationTokenAddress = "0x622A42eeC118304Eeb76Bf1Ac0dc08023BdF61f1";
}

if (mainnetAddress) {
  xtraAddress = "";
  allocationTokenAddress = "";
}

let Xtra, AllocationToken;
let toDistibuteSeed = [];
let toDistibutePresale = [];
let toDistibutePresale2 = [];
let toDistibuteTeam = [];

if (testnetAddresses) {
  toDistibuteSeed = [
    {
      address: "0xd9D36eC778455f3bCC7D4D74761304b3b55e540e",
      amount: toWei("400000000"),
      pool: 1,
    },
    {
      address: "0x51182d69af4e3e42147829895dE483857D34cDcF",
      amount: toWei("100000000"),
      pool: 1,
    },
    {
      address: "0xCCFb2ebbDBfa8f476402681d7E809D852398C8B6",
      amount: toWei("100000000"),
      pool: 1,
    },
    {
      address: "0xa02f8b6dA0bf4FAA3Ae0498043F3C2A77199Ee10",
      amount: toWei("100000000"),
      pool: 1,
    },
    {
      address: "0x0ee7B32D94552a2c2865fbdD50a25Fc478ED3332",
      amount: toWei("100000000"),
      pool: 1,
    },
    {
      address: "0x2236E49a5432a82501b786B9C12c84056Fc788F2",
      amount: toWei("100000000"),
      pool: 1,
    },
    {
      address: "0x3839D380f3726E255dF14bC3Ec222965B19685D9",
      amount: toWei("100000000"),
      pool: 1,
    },
  ];
  toDistibutePresale = [
    {
      address: "0xd9D36eC778455f3bCC7D4D74761304b3b55e540e",
      amount: toWei("750000000"),
      pool: 2,
    },
    {
      address: "0x1eD6cF7911AF6ac584bcb4B919CA341CE21D2272",
      amount: toWei("750000000"),
      pool: 2,
    },
    {
      address: "0xB8FB0807aA0BED4aeD8B578D1772717eAb0f4273",
      amount: toWei("500000000"),
      pool: 2,
    },
  ];
  toDistibutePresale2 = [
    {
      address: "0x04dcBc1B489b8D476e3f00a54866316fa107580b",
      amount: toWei("750000000"),
    },
    {
      address: "0x11765155d2c9000b9436701B898f4b366d8cc5Cf",
      amount: toWei("750000000"),
    },
  ];
  toDistibuteTeam = [
    {
      address: "0x3CB5723f44308B978fEeA8dF8f4BEA3fB856E70B",
      amount: toWei("1000000000"),
      pool: 4,
    },
    {
      address: "0x0203889F3D71EDcf03eD023f90329614FB3f7c92",
      amount: toWei("1000000000"),
      pool: 4,
    },
  ];
} else if (mainnetAddress) {
}

module.exports = async function (deployer, network, accounts) {
  if (!mainnetAddress && !testnetAddresses) {
    toDistibuteSeed = [
      {
        address: accounts[2],
        amount: toWei("1000000000"),
        pool: 1,
      },
    ];
    toDistibutePresale = [
      {
        address: accounts[3],
        amount: toWei("2000000000"),
        pool: 2,
      },
    ];
    toDistibutePresale2 = [
      {
        address: accounts[4],
        amount: toWei("1500000000"),
      },
    ];
    toDistibuteTeam = [
      {
        address: accounts[5],
        amount: toWei("2000000000"),
        pool: 4,
      },
    ];
  }
  const seedAddresses = [];
  const seedAmounts = [];
  const seedPools = [];
  for (let i = 0; i < toDistibuteSeed.length; i++) {
    seedAddresses.push(toDistibuteSeed[i].address);
    seedAmounts.push(toDistibuteSeed[i].amount);
    seedPools.push(toDistibuteSeed[i].pool);
  }

  const presaleAddresses = [];
  const presaleAmounts = [];
  const presalePools = [];
  for (let i = 0; i < toDistibutePresale.length; i++) {
    presaleAddresses.push(toDistibutePresale[i].address);
    presaleAmounts.push(toDistibutePresale[i].amount);
    presalePools.push(toDistibutePresale[i].pool);
  }

  const teamAddresses = [];
  const teamAmounts = [];
  const teamPools = [];
  for (let i = 0; i < toDistibuteTeam.length; i++) {
    teamAddresses.push(toDistibuteTeam[i].address);
    teamAmounts.push(toDistibuteTeam[i].amount);
    teamPools.push(toDistibuteTeam[i].pool);
  }

  AllocationToken = await AlloactionXtraTokenArtifact.deployed();
  for (let i = 0; i < toDistibutePresale2.length; i++) {
    await AllocationToken.transfer(
      toDistibutePresale2[i].address,
      toDistibutePresale2[i].amount
    );
  }

  if (xtraAddress) {
    Xtra = await XtraArtifact.deployed();

    await Xtra.addInvestors(seedAddresses, seedAmounts, seedPools);

    await Xtra.addInvestors(presaleAddresses, presaleAmounts, presalePools);

    await Xtra.addInvestors(teamAddresses, teamAmounts, teamPools);
  }
};
