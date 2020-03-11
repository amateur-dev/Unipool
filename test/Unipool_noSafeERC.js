const { time } = require("@openzeppelin/test-helpers");
const { expect } = require("chai");
const helper = require("ganache-time-traveler");

// const zUniPool = artifacts.require("zUniPool");
const unipool = artifacts.require("Unipool");


//SNX Unipool used to buy SNX
const erc20Abi = require("../build/contracts/IERC20.json").abi;
const snxAddress = "0xC011a73ee8576Fb46F5E1c5751cA3B9Fe0af2a6F";
const snxContract = new web3.eth.Contract(erc20Abi, snxAddress);

// //Constants
// const approval = "9999999999000000000000000000";
// const gas2Use = "1000000";
// const oneSethLP = "1000000000000000000";
// const oneHalfSethLP = "500000000000000000";
// const oneEth = "1000000000000000000";
// const onHundredEth = "100000000000000000000";
// const oneThousandEth = "1000000000000000000000";
// const tenThousandEth = "10000000000000000000000";
// const fiftyThousandEth = "50000000000000000000000";
// const testInterval = time.duration.hours(1).toNumber();
// //sETH Address
// const sethAddress = "0x5e74c9036fb86bd7ecdcb084a0673efc32ea31cb";


contract("unipool", async accounts => {
    unipool = await unipool.deployed(snxAddress);
    const unipoolAddress = unipool.address
    console.log(unipoolAddress)
});
