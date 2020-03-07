const { BN, ether } = require("@openzeppelin/test-helpers");
const { expect } = require("chai");

const iUnipool = artifacts.require("iUniPool");

//DeFiZap Unipool General
const unipoolGeneralAbi = require("./abis/unipoolGeneralABI.json");
const unipoolGeneralAddress = "0x97402249515994Cc0D22092D3375033Ad0ea438A";
const unipoolGeneralContract = new web3.eth.Contract(
  unipoolGeneralAbi,
  unipoolGeneralAddress
);

//Uniswap Exchange
const uniswapExchangeAbi = require("./abis/uniswapExchangeABI.json");
const uniswapExchangeAddress = "0xe9Cf7887b93150D4F2Da7dFc6D502B216438F244"; //sETH LP Token Exchange
const uniswapExchangeContract = new web3.eth.Contract(
  uniswapExchangeAbi,
  uniswapExchangeAddress
);

//Synthetix Unipool
const unipoolAbi = require("../build/contracts/Unipool.json").abi;
const unipoolAddress = "0x48D7f315feDcaD332F68aafa017c7C158BC54760";
const unipoolContract = new web3.eth.Contract(
  unipoolAbi,
  uniswapExchangeAddress
);

//Constants
const approval = "9999999999000000000000000000";
const gas2Use = "1000000";
const oneEth = '1000000000000000000'
const oneThousandEth = "1000000000000000000000";
const tenThousandEth = "10000000000000000000000";
//sETH Address
const sethAddress = "0x5e74c9036fb86bd7ecdcb084a0673efc32ea31cb";

contract("iUnipool", async accounts => {
  let iUnipoolContract;
  const toWhomToIssue = accounts[1];
  const anotherUser = accounts[2];
  before(async () => {

    iUnipoolContract = await iUnipool.deployed();

    // Some risidual is recieved back when zapping in (~500-800 ETH on 10k ETH)
    await unipoolGeneralContract.methods
      .LetsInvest(sethAddress, toWhomToIssue)
      .send({ from: toWhomToIssue, value: oneThousandEth, gas: gas2Use });

    //Recieve approval from sETH Uniswap Exchange for unipool to interact with sETH LP
    await uniswapExchangeContract.methods
      .approve(unipoolAddress, approval)
      .send({ from: toWhomToIssue });

    let allowance = await uniswapExchangeContract.methods
    .allowance(toWhomToIssue, unipoolAddress).call()

    console.log("allowance", allowance);
  });

  it("should not have any LP tokens staked", async () => {
    let earnedSNX = await iUnipoolContract.howMuchHasThisContractEarned.call();
    expect(earnedSNX.toNumber()).to.equal(0)
  });

  it("Should allow staking", async () => {
    let balance = await uniswapExchangeContract.methods
    .balanceOf(toWhomToIssue).call()
    expect(balance).to.be.bignumber.above(new BN('0'))

    let zUniRecieved = await iUnipoolContract.stakeMyShare(new BN(balance/2))
    // let snxTokenAddress = await iUnipoolContract.stakeMyShare.call();
  });
});
