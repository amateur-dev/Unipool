const { time } = require("@openzeppelin/test-helpers");
const { expect } = require("chai");
const helper = require("ganache-time-traveler");

const zUniPool = artifacts.require("zUniPool");
const unipool = artifacts.require("Unipool");

const erc20Abi = require("../build/contracts/IERC20.json").abi;
const uniswapExchangeAbi = require("./abis/uniswapExchangeABI.json");
const unipoolGeneralAbi = require("./abis/unipoolGeneralABI.json");

//Constants
const approval = "9999999999000000000000000000";
const gas2Use = "1000000";
const oneSethLP = "1000000000000000000";
const oneHundredSethLP = "100000000000000000000";
const oneHalfSethLP = "500000000000000000";
const oneEth = "1000000000000000000";
const oneHundredEth = "100000000000000000000";
const oneThousandEth = "1000000000000000000000";
const tenThousandEth = "10000000000000000000000";
const fiftyThousandEth = "50000000000000000000000";
const testInterval = time.duration.hours(1).toNumber();
//sETH Token Address
const sethTokenAddress = "0x5e74c9036fb86bd7ecdcb084a0673efc32ea31cb";
//sETH Exchange Address
const sethAddress = "0xe9Cf7887b93150D4F2Da7dFc6D502B216438F244";
//SNX Token Address
const snxTokenAddress = "0xc011a72400e58ecd99ee497cf89e3775d4bd732f";
//SNX Exchange Address
const snxAddress = "0x3958B4eC427F8fa24eB60F42821760e88d485f7F";
//DefiZap Unipool General Address
const unipoolGeneralAddress = "0x97402249515994Cc0D22092D3375033Ad0ea438A";

//SNX Token
const snxContract = new web3.eth.Contract(erc20Abi, snxTokenAddress);

//SNX Uniswap Exchange
const snxUniswapExchangeContract = new web3.eth.Contract(
  uniswapExchangeAbi,
  snxAddress
);

//sETH Uniswap Exchange
const sethUniswapExchangeContract = new web3.eth.Contract(
  uniswapExchangeAbi,
  sethAddress
);

//DeFiZap Unipool General
const unipoolGeneralContract = new web3.eth.Contract(
  unipoolGeneralAbi,
  unipoolGeneralAddress
);

contract("unipool", async accounts => {
  let unipoolAddress = (zUniPoolAddress = null);
  let unipoolContract = (zUniPoolContract = null);
  const boss = accounts[0];
  const toWhomToIssue = accounts[1];
  const anotherUser = accounts[2];

  before(async () => {
    unipoolContract = await unipool.deployed();
    unipoolAddress = unipoolContract.address;

    zUniPoolContract = await zUniPool.deployed();
    zUniPoolAddress = zUniPoolContract.address;

    await snxUniswapExchangeContract.methods
      .ethToTokenTransferInput(1, 1683899800, unipoolAddress)
      .send({ from: toWhomToIssue, value: tenThousandEth, gas: gas2Use });

    let unipoolSNXBalance = await snxContract.methods
      .balanceOf(unipoolAddress)
      .call();

    await unipoolContract.setRewardDistribution(boss, { from: boss });

    await unipoolContract.notifyRewardAmount(
      unipoolSNXBalance,
      time.duration.weeks(4),
      { from: boss }
    );

    // Allows toWhomToIssue to stake sETH LP direcly to the Unipool contract
    await sethUniswapExchangeContract.methods
      .approve(unipoolAddress, approval)
      .send({ from: toWhomToIssue });

    // Allows toWhomToIssue to stake sETH LP to the zUniPool contract
    await sethUniswapExchangeContract.methods
      .approve(zUniPoolAddress, approval)
      .send({ from: toWhomToIssue });

    await unipoolGeneralContract.methods
      .LetsInvest(sethTokenAddress, toWhomToIssue)
      .send({ from: toWhomToIssue, value: tenThousandEth, gas: gas2Use });

    let lpBalance = await sethUniswapExchangeContract.methods
      .balanceOf(toWhomToIssue)
      .call();
    console.log("toWhomToIssue LP Balance", web3.utils.fromWei(lpBalance));
  });

  beforeEach(async () => {
    let snapShot = await helper.takeSnapshot();
    snapshotId = snapShot["result"];
  });

  afterEach(async () => {
    await helper.revertToSnapshot(snapshotId);
  });

  it("Unipool Contract has a Balance", async () => {
    let unipoolSNXBalance = await snxContract.methods
      .balanceOf(unipoolAddress)
      .call();
    console.log('Unipool SNX Balance', web3.utils.fromWei(unipoolSNXBalance));
  });

  it("Unipool get reward ", async () => {

    let LpBalance = await sethUniswapExchangeContract.methods
      .balanceOf(toWhomToIssue)
      .call();
    let halfOfBalance = web3.utils.fromWei(LpBalance, "ether") / 2;
    halfOfBalance = web3.utils.toWei(halfOfBalance.toString());

    await unipoolContract.stake(oneThousandEth, { from: toWhomToIssue });

    await helper.advanceTimeAndBlock(testInterval);

    // await unipoolContract.stake(oneSethLP, { from: toWhomToIssue }); // Uncommenting this line results in very high reward numbers

    let reward = await unipoolContract.earned(toWhomToIssue);
    console.log("reward", web3.utils.fromWei(reward));

    await unipoolContract.getReward({ from: toWhomToIssue});
  });
});
