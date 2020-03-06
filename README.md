# Unipool

This is repo is built on top of the Unipool repo by the user k06a (forked from).  The only addition to this repo as of now is the zUnipool.sol

## Objective of the zUnipool

zUnipool contract tokenises the staking of the Uniswap LP tokens into the Unipool contract, deployed on the mainnet by [Synthetix](https://help.synthetix.io/hc/en-us/articles/360043634533).  The staking actually happens by using the Unipool contract that is availiable as contracts/Unipool.sol.

As of now the staking of the Uniswap LP tokens does not provide you with an ERC20 token in return, thus, making the entire staking portion non-transferable.  

The objective of the zUnipool contract is to provide the user with an ERC20 token which represents this staking and appreciates in value considering the SNX rewards that are accrued on account of staking.

### Current Status

This contract has been in internal development and testing for over 2 weeks (at the time of this writing 6 March 2020). Various aspects of this contract has been tested multiple times.  We are also now completing our programmed testing results and will update this repo soon.

However, at this stage, we are _inviting you_ to please review the contract zUnipool.sol and provide your feedback by creating issues or PR on the code.

A full video run down of one of the final use and internal testing (manual though) is available [here](https://www.loom.com/share/53ead589fa584db49c228d6c0352b5f6)

