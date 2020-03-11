const { time } = require("@openzeppelin/test-helpers");
const { expect } = require("chai");
const helper = require("ganache-time-traveler");

const zUniPool = artifacts.require("zUniPool");
const unipool = artifacts.require("Unipool");

//SNX Token Address
const erc20Abi = require("../build/contracts/IERC20.json").abi;
const snxAddress = "0xC011a73ee8576Fb46F5E1c5751cA3B9Fe0af2a6F";
const snxContract = new web3.eth.Contract(erc20Abi, snxAddress);

//Uniswap Exchange
const uniswapExchangeAbi = require("./abis/uniswapExchangeABI.json");
const uniswapExchangeContract = new web3.eth.Contract(
  uniswapExchangeAbi,
  "0x3958B4eC427F8fa24eB60F42821760e88d485f7F" // SNX Exchange Address
);

//DeFiZap Unipool General
const unipoolGeneralAbi = require("./abis/unipoolGeneralABI.json");
const unipoolGeneralAddress = "0x97402249515994Cc0D22092D3375033Ad0ea438A";
const unipoolGeneralContract = new web3.eth.Contract(
  unipoolGeneralAbi,
  unipoolGeneralAddress
);

//Constants
const approval = "9999999999000000000000000000";
const gas2Use = "1000000";
const oneSethLP = "1000000000000000000";
const oneHalfSethLP = "500000000000000000";
const oneEth = "1000000000000000000";
const oneHundredEth = "100000000000000000000";
const oneThousandEth = "1000000000000000000000";
const tenThousandEth = "10000000000000000000000";
const fiftyThousandEth = "50000000000000000000000";
const testInterval = time.duration.hours(1).toNumber();
//sETH Address
const sethAddress = "0x5e74c9036fb86bd7ecdcb084a0673efc32ea31cb";

contract("unipool", async accounts => {
  let unipoolAddress = (zUniPoolAddress = null);
  let unipoolContract = (zUniPoolContract = null);
  const boss = accounts[0];
  const toWhomToIssue = accounts[1];
  const anotherUser = accounts[2];

  before(async () => {
    unipoolContract = await unipool.deployed();
    unipoolAddress = unipoolContract.address;
    console.log(unipoolAddress);

    zUniPoolContract = await zUniPool.deployed();
    zUniPoolAddress = zUniPoolContract.address;
    console.log(zUniPoolAddress);

    await uniswapExchangeContract.methods
      .ethToTokenTransferInput(1, 1683899800, unipoolAddress)
      .send({ from: toWhomToIssue, value: oneThousandEth, gas: gas2Use });

    let unipoolSNXBalance = await snxContract.methods
      .balanceOf(unipoolAddress)
      .call();

    await unipoolContract.setRewardDistribution(boss, { from: boss });

    await unipoolContract.notifyRewardAmount(
      unipoolSNXBalance,
      time.duration.weeks(4),
      { from: boss }
    );

    // Get sETH LP Tokens for tester accounts
    await unipoolGeneralContract.methods
      .LetsInvest(sethAddress, toWhomToIssue)
      .send({ from: toWhomToIssue, value: tenThousandEth, gas: gas2Use });
      console.log('LP balance', web3.utils.fromWei(await uniswapExchangeContract.methods.balanceOf(toWhomToIssue).call()))

    await unipoolGeneralContract.methods
      .LetsInvest(sethAddress, anotherUser)
      .send({ from: anotherUser, value: oneHundredEth, gas: gas2Use });

    await uniswapExchangeContract.methods
      .approve(unipoolAddress, approval)
      .send({ from: anotherUser });

    await uniswapExchangeContract.methods
      .approve(zUniPoolAddress, approval)
      .send({ from: toWhomToIssue });
  });

  it("Unipool Contract has a Balance", async () => {
    let unipoolSNXBalance = await snxContract.methods
      .balanceOf(unipoolAddress)
      .call();
    console.log(web3.utils.fromWei(unipoolSNXBalance));
  });
});
