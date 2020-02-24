const Migrations = artifacts.require('./Migrations.sol');
const iUniPool = artifacts.require('./iUniPool.sol');

module.exports = function (deployer) {
    deployer.deploy(iUniPool, "0x48D7f315feDcaD332F68aafa017c7C158BC54760");
};
