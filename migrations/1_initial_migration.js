const Migrations = artifacts.require('./Migrations.sol');
const Unipool = artifacts.require('./Unipool.sol');
const zUniPool = artifacts.require('./zUniPool.sol');



module.exports = async function (deployer) {
    await deployer.deploy(Migrations);
    await deployer.deploy(Unipool);
    await deployer.deploy(zUniPool, Unipool.address);
};
