const Migrations = artifacts.require('./Migrations.sol');
const zUniPool = artifacts.require('./zUniPool.sol');


module.exports = function (deployer) {
    deployer.deploy(Migrations);
    deployer.deploy(zUniPool);

};
