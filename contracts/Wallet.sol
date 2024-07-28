// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./PriceConsumer.sol";

contract Wallet is Ownable {
  uint public constant usdDecimals = 2;
  uint public constant nftDecimals = 18;

  uint public nftPrice;
  uint public ownerEthAmountToWithdraw;
  uint public ownerTokenAmountToWithdraw;

  address public oracleEthUsdPrice;
  address public oracleTokenEthPrice;

  PriceConsumerV3 public ethUsdContract;
  PriceConsumerV3 public tokenEthContract;

  mapping(address => uint256) public userEthDeposit;
  // user => token => amount
  mapping(address => mapping(address => uint256)) public userTokenDeposit;

  constructor(address clEthUsd, address clTokenUsd) {
    oracleEthUsdPrice = clEthUsd;
    oracleTokenEthPrice = clTokenUsd;
    ethUsdContract = new PriceConsumerV3(oracleEthUsdPrice);
    tokenEthContract = new PriceConsumerV3(oracleTokenEthPrice);
  }

  receive() external payable {
    registerUserDeposit(msg.sender, msg.value);
  }

  function getUserDeposit(
    address user,
    address token
  ) public view returns (uint256) {
    return userTokenDeposit[user][token];
  }

  function getNFTPrice() external view returns (uint256) {
    uint256 price;
    int iPrice;
    AggregatorV3Interface nftOraclePrice = AggregatorV3Interface(
      oracleTokenEthPrice
    );
    (, iPrice, , , ) = nftOraclePrice.latestRoundData();
    price = uint256(iPrice);
    return price;
  }

  function convertEthInUSD(address user) public view returns (uint) {
    uint ethPriceDecimals = ethUsdContract.getPriceDecimals();
    uint ethPrice = uint(ethUsdContract.getLatestPrice());
    uint divDecs = nftDecimals + ethPriceDecimals - usdDecimals;
    uint userUSDDeposit = (userEthDeposit[user] * ethPrice) / (10 ** divDecs);
    return userUSDDeposit;
  }

  function convertUSDinETH(uint usdAmount) public view returns (uint) {
    uint ethPriceDecimals = ethUsdContract.getPriceDecimals();
    uint ethPrice = uint(ethUsdContract.getLatestPrice());
    uint mulDecs = nftDecimals + ethPriceDecimals - usdDecimals;
    uint ethAmount = (usdAmount * (10 ** mulDecs)) / ethPrice;
    return ethAmount;
  }

  function transferEthAmountOnBuy(uint nftNumber) public {
    uint calcTotalUsdAmount = nftPrice * nftNumber * (10 ** 2); // in USD
    uint ethAmountForBuying = convertUSDinETH(calcTotalUsdAmount);
    require(
      userEthDeposit[msg.sender] >= ethAmountForBuying,
      "User has not enough funds to buy NFT"
    );
    ownerEthAmountToWithdraw += ethAmountForBuying;
    userEthDeposit[msg.sender] -= ethAmountForBuying;
  }

  function userDeposit(address token, uint amount) external {
    SafeERC20.safeTransferFrom(
      IERC20(token),
      msg.sender,
      address(this),
      amount
    );
    userTokenDeposit[msg.sender][token] += amount;
  }

  function convertNFTPriceInUSD() public view returns (uint) {
    uint tokenPriceDecimals = tokenEthContract.getPriceDecimals(); // 18
    uint tokenPrice = uint(tokenEthContract.getLatestPrice());

    uint ethPriceDecimals = ethUsdContract.getPriceDecimals();
    uint erhPrice = uint(ethUsdContract.getLatestPrice());
    uint divDecs = tokenPriceDecimals + ethPriceDecimals - usdDecimals;
    uint tokenUSDPrice = (tokenPrice * erhPrice) / (10 ** divDecs);
    return tokenUSDPrice;
  }

  function convertUSDInNFTAmount(uint usdAmount) public view returns (uint) {
    uint tokenPriceDecimals = tokenEthContract.getPriceDecimals();
    uint tokenPrice = uint(tokenEthContract.getLatestPrice());

    uint ethPriceDecimals = ethUsdContract.getPriceDecimals();
    uint ethPrice = uint(ethUsdContract.getLatestPrice());

    uint mulDecs = tokenPriceDecimals + ethPriceDecimals - usdDecimals;
    uint convertAmountInEth = (usdAmount * (10 ** mulDecs)) / ethPrice;
    uint convertETHInToken = convertAmountInEth / tokenPrice;

    uint totalCosts = (convertETHInToken * tokenPrice) / (10 ** 24);
    uint remainingUSD = usdAmount - totalCosts;
    return (convertETHInToken, remainingUSD);
  }

  function getNativeCoinBalance() public view returns (uint) {
    return address(this).balance;
  }

  function getTokenBalance(address _token) public view returns (uint256) {
    return IERC20(_token).balanceOf(address(this));
  }

  function nativeCoinWithdraw() external onlyOwner {
    require(ownerEthAmountToWithdraw > 0, "Owner has no funds to withdraw");
    uint256 tmpAmount = ownerEthAmountToWithdraw;
    ownerEthAmountToWithdraw = 0;
    (bool sent, ) = payable(_msgSender()).call{ value: tmpAmount }("");
    require(sent, "Failed to send Ether");
  }

  function userETHWithdraw() external {
    require(userEthDeposit[msg.sender] > 0, "User has no funds to withdraw");
    (bool sent, ) = payable(msg.sender).call{
      value: userEthDeposit[msg.sender]
    }("");
    require(sent, "Failed to send Ether");
    userEthDeposit[msg.sender] = 0;
  }

  function tokenWithdraw(address token) external onlyOwner {
    require(ownerTokenAmountToWithdraw > 0, "Owner has no funds to withdraw");
    uint256 tmpAmount = ownerTokenAmountToWithdraw;
    ownerTokenAmountToWithdraw = 0;
    SafeERC20.safeTransfer(IERC20(token), _msgSender(), tmpAmount);
  }

  function userTokenWithdraw(address token) external {
    require(
      userTokenDeposit[msg.sender][token] > 0,
      "User has no funds to withdraw"
    );
    uint256 tmpAmount = userTokenDeposit[msg.sender][token];
    userTokenDeposit[msg.sender][token] = 0;
    SafeERC20.safeTransfer(IERC20(token), msg.sender, tmpAmount);
  }
}
