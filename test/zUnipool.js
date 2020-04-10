const { time } = require('openzeppelin-test-helpers');

const zUnipool = artifacts.require('zUnipool');
const GeneralZap = artifacts.require('UniSwapAddLiquityV3_General');
const IERC20 = artifacts.require('IERC20');

contract('zUnipool', function (accounts) {
    const firstUser = accounts[0];
    const secondUser = accounts[1];
    const thirdUser = accounts[2];

    let sEthToken;
    let sEthLpToken;
    let generalZap;
    let pool;

    before(async function () {
        // Mainnet addresses
        sEthToken = await IERC20.at('0x5e74C9036fb86BD7eCdcb084a0673EFc32eA31cb');
        sEthLpToken = await IERC20.at('0xe9Cf7887b93150D4F2Da7dFc6D502B216438F244');
        generalZap = await GeneralZap.at('0x97402249515994Cc0D22092D3375033Ad0ea438A');

        // All users invest in sETH
        await generalZap.LetsInvest(sEthToken.address, firstUser, { from: firstUser, value: web3.utils.toWei(new web3.utils.BN('10')) });
        await generalZap.LetsInvest(sEthToken.address, secondUser, { from: secondUser, value: web3.utils.toWei(new web3.utils.BN('10')) });
        await generalZap.LetsInvest(sEthToken.address, thirdUser, { from: thirdUser, value: web3.utils.toWei(new web3.utils.BN('10')) });

        // Deploy zUnipool
        pool = await zUnipool.new();

        // All users approve zUnipool to access their sETH
        const uintMax = new web3.utils.BN('2').pow(new web3.utils.BN('256')).sub(new web3.utils.BN('1'))
        await sEthLpToken.approve(pool.address, uintMax, { from: firstUser });
        await sEthLpToken.approve(pool.address, uintMax, { from: secondUser });
        await sEthLpToken.approve(pool.address, uintMax, { from: thirdUser });
    });

    it('three user interaction', async function () {
        console.log('1. First user is able to stake LP tokens at a price of 1:1')
        const firstUserStakeAmount = web3.utils.toWei('1').toString(10);
        await pool.stakeMyShare(firstUserStakeAmount, { from: firstUser });
        assert.equal((await pool.balanceOf.call(firstUser)).toString(10), firstUserStakeAmount, 'wrong first user staked amount');

        console.log('2. Second user is also able to stake LP, immediately, at a price of 1:1')
        const secondUserStakeAmount = web3.utils.toWei(new web3.utils.BN('2'))
        const secondUserAllowedRange = new web3.utils.BN('10000000000000')
        await pool.stakeMyShare(secondUserStakeAmount, { from: secondUser });
        const secondUserActualStakeAmount = await pool.balanceOf.call(secondUser)
        assert.isTrue(secondUserActualStakeAmount.gte(secondUserStakeAmount.sub(secondUserAllowedRange)), 'wrong second user staked amount');

        console.log('3. Immediately, the First User is able to withdraw its LP with the same number of LP tokens')
        await pool.getMyStakeOut(firstUserStakeAmount);

        console.log('4. Immediately, the Second User is able to check the value of its zUNI tokens ' +
        'and it should return, at least, the same number of LP tokens that it staked (or higher)')
        const secondUserStakeWorth = await pool.howMuchIszUNIWorth.call(secondUserStakeAmount);
        assert.isTrue(secondUserStakeWorth.gte(secondUserActualStakeAmount.sub(secondUserAllowedRange)), 'wrong second user stake worth');

        console.log('5. Third User is able to stake LP tokens, after a week of time lapse, ' +
        'but the zUNI Tokens issued to the Third User is not at a price ratio of 1:1, ' +
        'but lesser number of zUNI Tokens compared to the number of LP tokens staked')
        //await time.increase(60 * 60 * 24 * 7);
        const thirdUserStakeAmount = web3.utils.toWei(new web3.utils.BN('3'));
        await pool.stakeMyShare(thirdUserStakeAmount, { from: thirdUser, gas: 6000000});
        const thirdUserBalance = await pool.balanceOf.call(thirdUser)
        assert.isTrue(thirdUserBalance.lte(thirdUserStakeAmount), 'wrong third user staked amount ' + thirdUserStakeAmount.toString(10) + ' ' + thirdUserBalance.toString(10));

        console.log('6. At the same time, Second User wants to burn a exactly half of its zUNI Tokens, and it is able to receive LP tokens. ' +
        'The LP tokens received at this stage by Second User is higher than half of the LP Tokens staked by the Second User')
        const secondUserBalanceBeforeExit = await sEthLpToken.balanceOf.call(secondUser);
        const secondUserExitAmount = secondUserStakeAmount.div(new web3.utils.BN('2'));
        await pool.getMyStakeOut(secondUserExitAmount, { from: secondUser });
        const secondUserBalanceAfterExit = await sEthLpToken.balanceOf.call(secondUser);
        const secondUserBalanceIncrease = secondUserBalanceAfterExit.sub(secondUserBalanceBeforeExit);
        assert.isTrue(secondUserBalanceIncrease.gte(secondUserExitAmount), 'wrong second user balance increase');
    });
});
