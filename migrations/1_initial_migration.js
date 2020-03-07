const Migrations = artifacts.require('./Migrations.sol');
const iUniPool = artifacts.require('./iUniPool.sol');


module.exports = function (deployer) {
    deployer.deploy(Migrations);
    deployer.deploy(iUniPool);

};
