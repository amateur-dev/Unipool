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
        await generalZap.LetsInvest(sEthToken.address, firstUser, { from: firstUser, value: web3.utils.toWei('10') });
        await generalZap.LetsInvest(sEthToken.address, secondUser, { from: secondUser, value: web3.utils.toWei('10') });
        await generalZap.LetsInvest(sEthToken.address, thirdUser, { from: thirdUser, value: web3.utils.toWei('10') });

        // Deploy zUnipool
        pool = await zUnipool.new();

        // All users approve zUnipool to access their sETH
        await sEthLpToken.approve(pool.address, await sEthLpToken.balanceOf.call(firstUser), { from: firstUser });
        await sEthLpToken.approve(pool.address, await sEthLpToken.balanceOf.call(secondUser), { from: secondUser });
        await sEthLpToken.approve(pool.address, await sEthLpToken.balanceOf.call(thirdUser), { from: thirdUser });
    });

    it('three user interaction', async function () {
        // 1. First user is able to stake LP tokens at a price of 1:1
        const firstUserStakeAmount = web3.utils.toWei('1').toString();
        await pool.stakeMyShare(firstUserStakeAmount, { from: firstUser });
        assert.equal((await pool.balanceOf.call(firstUser)).toString(), firstUserStakeAmount, 'wrong first user staked amount');

        // 2. Second user is also able to stake LP, immediately, at a price of 1:1
        const secondUserStakeAmount = web3.utils.toWei('2').toString();
        await pool.stakeMyShare(secondUserStakeAmount, { from: secondUser });
        assert.equal((await pool.balanceOf.call(secondUser)).toString(), secondUserStakeAmount, 'wrong second user staked amount');

        // 3. Immediately, the First User is able to withdraw its LP with the same number of LP tokens
        await pool.getMyStakeOut(firstUserStakeAmount);

        // 4. Immediately, the Second User is able to check the value of its zUNI tokens
        //    and it should return, at least, the same number of LP tokens that it staked (or higher)
        const secondUserStakeWorth = await pool.howMuchIszUNIWorth.call(secondUserStakeAmount);
        assert.isAtLeast(parseInt(secondUserStakeWorth.toString()), parseInt(secondUserStakeAmount), 'wrong second user stake worth');

        // 5. Third User is able to stake LP tokens, after a week of time lapse,
        //    but the zUNI Tokens issued to the Third User is not at a price ratio of 1:1,
        //    but lesser number of zUNI Tokens compared to the number of LP tokens staked
        await time.increase(60 * 60 * 24 * 7);
        const thirdUserStakeAmount = web3.utils.toWei('3').toString();
        await pool.stakeMyShare(thirdUserStakeAmount, { from: thirdUser });
        assert.isBelow(parseInt((await pool.balanceOf.call(thirdUser)).toString()), parseInt(thirdUserStakeAmount), 'wrong third user staked amount');

        // 6. At the same time, Second User wants to burn a exactly half of its zUNI Tokens, and it is able to receive LP tokens.
        //    The LP tokens received at this stage by Second User is higher than half of the LP Tokens staked by the Second User
        const secondUserBalanceBeforeExit = await sEthLpToken.balanceOf.call(secondUser);
        const secondUserExitAmount = secondUserStakeAmount / 2;
        await pool.getMyStakeOut(secondUserExitAmount.toString(), { from: secondUser });
        const secondUserBalanceAfterExit = await sEthLpToken.balanceOf.call(secondUser);
        const secondUserBalanceIncrease = secondUserBalanceAfterExit.sub(secondUserBalanceBeforeExit);
        assert.isAbove(parseInt(secondUserBalanceIncrease.toString()), parseInt(secondUserExitAmount), 'wrong second user balance increase');
    });
});
