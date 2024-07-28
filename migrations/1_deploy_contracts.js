const Wallet = artifacts.require("Wallet");
const PriceConsumerV3 = artifacts.require("PriceConsumerV3");
const LinkToken = artifacts.require("LinkToken");

const ethUsdContract = "0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419";
const azukiPriceContract = "0xA8B9A447C73191744D5B79BcE864F343455E1150";

module.exports = async function (deployer, network, accounts) {
  await deployer.deploy(Wallet, ethUsdContract, azukiPriceContract);
  const wallet = await Wallet.deployed();
  console.log("Wallet deployed at address: ", wallet.address);

  await deployer.deploy(Token, "Test token", "TST", 1000000);
  const token = await Token.deployed();
  console.log("Token deployed at address: ", token.address);

  await deployer.deploy(PriceConsumerV3, ethUsdContract);
  const ethUsdPrice = await PriceConsumerV3.deployed();
  console.log(
    "Deployed Price ETH/USD Mockup at address: ",
    ethUsdPrice.address
  );

  await deployer.deploy(PriceConsumerV3, azukiPriceContract);
  const azukiUsdPrice = await PriceConsumerV3.deployed();
  console.log(
    "Deployed Price Azuki/USD Mockup at address: ",
    azukiUsdPrice.address
  );
};
