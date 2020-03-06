# Unipool

This is repo is built on top of the Unipool repo by the user k06a (forked from).  The only addition to this repo as of now is the zUnipool.sol

## Objective of the zUnipool

zUnipool contract tokenises the staking of the Uniswap LP tokens into the Unipool contract, deployed on the mainnet by [Synthetix](https://help.synthetix.io/hc/en-us/articles/360043634533).  The staking actually happens by using the Unipool contract that is availiable as contracts/Unipool.sol.

As of now the staking of the Uniswap LP tokens does not provide you with an ERC20 token in return, thus, making the entire staking portion non-transferable.  

The objective of the zUnipool contract is to provide the user with an ERC20 token which represents this staking and appreciates in value considering the SNX rewards that are accrued on account of staking.
