// Import necessary dependencies
const {
  BN,
  constants,
  expectEvent,
  expectRevert,
  time,
} = require("@openzeppelin/test-helpers");
const { inTransaction } = require("@openzeppelin/test-helpers/src/expectEvent");
const { web3 } = require("@openzeppelin/test-helpers/src/setup");
const { ZERO_ADDRESS } = constants;
const { expect } = require("chai");
const { default: Contract } = require("web3/eth/contract");

const Token = artifacts.require("Token");
const Wallet = artifacts.require("Wallet");
const PriceConsumerV3 = artifacts.require("PriceConsumerV3");
const AggregatorProxy = artifacts.require("AggregatorProxy");

/**
 * Network: mainnet
 * Aggregator: ETH/USD
 * Address: 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419
 * Azuki: 0xA8B9A447C73191744D5B79BcE864F343455E1150
 */

const ethUsdContract = "0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419";
const azukiPriceContract = "0xA8B9A447C73191744D5B79BcE864F343455E1150";

const fromWei = (x) => web3.utils.fromWei(x.toString());
const toWei = (x) => web3.utils.toWei(x.toString());
const fromWei8Decimals = (x) => Number(x) / Math.pow(10, 8);
const toWei8Decimals = (x) => x * Math.pow(10, 8);
const fromWei2Decimals = (x) => Number(x) / Math.pow(10, 2);
const toWei2Decimals = (x) => x * Math.pow(10, 2);

contract("Wallet", function (accounts) {
  const [deployer, firstAccount, secondAccount, fakeOwner] = accounts;

  it("retrive deployed contract", async function () {
    tokenContract = await Token.deployed();
    expect(tokenContract.address).to.be.not.equal(ZERO_ADDRESS);
    expect(tokenContract.address).to.match(/0x[0-9a-fA-F]{40}/);

    walletContract = await Wallet.deployed();

    priceEthUsd = await PriceConsumerV3.deployed();

    console.log(
      "Token contract address: ",
      tokenContract.address,
      "Wallet contract address: ",
      walletContract.address,
      "Price ETH/USD contract address: ",
      priceEthUsd.address
    );
  });

  //distribuiamo token al deployer e a due account, controlliamo i saldi
  it("distrubute some tokens from deployer", async function () {
    await tokenContract.transfer(firstAccount, toWei(100000));
    await tokenContract.transfer(secondAccount, toWei(150000));

    balanceDeployer = await tokenContract.balanceOf(deployer);
    balanceFirstAccount = await tokenContract.balanceOf(firstAccount);
    balanceSecondAccount = await tokenContract.balanceOf(secondAccount);

    console.log(
      "Deployer balance: ",
      fromWei(balanceDeployer),
      "First account balance: ",
      fromWei(balanceFirstAccount),
      "Second account balance: ",
      fromWei(balanceSecondAccount)
    );
  });

  it("Eth / USD price", async function () {
    ret = await priceEthUsd.getPriceDecimals();
    console.log("Price decimals: ", ret.toString());
    res = await priceEthUsd.getLatestPrice();
    console.log("Latest price: ", fromWei8Decimals(res.toString()));
  });

  it("Azuki / Eth price", async function () {
    azukiEthData = await AggregatorProxy.at(azukiPriceContract);
    ret = await azukiEthData.decimals();
    console.log("Price decimals: ", ret.toString());
    res = await azukiEthData.latestRoundData();
    console.log(fromWei(res[1]));

    console.log(fromWei(await walletContract.getNFTPrice()));
  });

  //convertiamo eth in usd e viceversa
  it("convert ETH to USD", async function () {
    await walletContract.sendTransaction({
      from: firstAccount,
      value: toWei(2),
    });
    ret = await walletContract.convertEthInUSD(firstAccount);
    console.log(fromWei2Decimals(ret));

    ret = await walletContract.convertUSDInETH(toWei2Decimals(5000));
    console.log(fromWei(ret));

    ret = await walletContract.convertNFTPriceInUSD();
    console.log(fromWei2Decimals(ret));

    ret = await walletContract.convertUSDInNFTAmount(toWei2Decimals(25000));
    console.log(ret[0].toString(), fromWei2Decimals(ret[1]));

    ret = await walletContract.convertUSDInNFTAmount(toWei2Decimals(48000));
    console.log(ret[0].toString(), fromWei2Decimals(ret[1]));
  });

  //approviamo il deposito di token, depositiamo token, controlliamo il saldo del wallet
  it("user buy some tokens", async function () {
    await tokenContract.approve(walletContract.address, toWei(25000), {
      from: firstAccount,
    });
    await walletContract.userDeposit(tokenContract.address, toWei(25000), {
      from: firstAccount,
    });
    res = await walletContract.getUserDeposit(
      firstAccount,
      tokenContract.address
    );
    console.log(fromWei(res));
    res = tokenContract.balanceOf(walletContract.address);
    console.log(fromWei(res));
  });

  //approviamo il prelievo di token, preleviamo token, controlliamo il saldo del wallet
  it("user deposit some tokens", async function () {
    await walletContract.userTokenWithdraw(
      tokenContract.address,
      toWei(10000),
      { from: firstAccount }
    );
    res = await walletContract.getUserDeposit(
      firstAccount,
      tokenContract.address
    );
    console.log(fromWei(res));
    res = tokenContract.balanceOf(walletContract.address);
    console.log(fromWei(res));
  });
});
