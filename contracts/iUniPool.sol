pragma solidity ^0.5.0;

import "./Unipool.sol";

contract iUniPool {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // --- ERC20 Data ---
    string public constant name = "DZSLT";
    string public constant symbol = "DZSLT";
    string public constant version = "1";
    uint8 public constant decimals = 18;
    uint256 public totalSupply;

    address public constant UnipoolAddress = 0x48D7f315feDcaD332F68aafa017c7C158BC54760;
    IERC20 public constant sETHTokenAddress = IERC20(
        0x5e74C9036fb86BD7eCdcb084a0673EFc32eA31cb
    );
    IERC20 public constant UniswapLiquityTokenAddress = IERC20(
        0xe9Cf7887b93150D4F2Da7dFc6D502B216438F244
    );
    IERC20 public constant SNXTokenAddress = IERC20(
        0xC011A72400E58ecD99Ee497CF89E3775d4bd732F
    );
    uint256 public totalLPTokensStaked;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    mapping(address => uint256) public LPTokensSupplied;

    // events
    event LPTokensStaked(address indexed staker, uint256 qtyStaked);
    event LPTokensWithdrawn(address indexed leaver, uint256 qtyWithdrawn);
    event Approval(address indexed src, address indexed guy, uint256 wad);
    event Transfer(address indexed src, address indexed dst, uint256 wad);

    constructor() public {
        approve_UniswapLTAddress();
    }

    function approve_UniswapLTAddress() internal {
        IERC20(UniswapLiquityTokenAddress).approve(
            address(this),
            ((2 ^ 256) - 1)
        );

    }

    function howMuchHasThisContractStaked()
        external
        view
        returns (uint256 LPTokens)
    {
        return Unipool(UnipoolAddress).balanceOf(address(this));
    }

    function howMuchHasThisContractEarned()
        external
        view
        returns (uint256 SNXEarned)
    {
        return Unipool(UnipoolAddress).earned(address(this));
    }

    function thisContractsWealth()
        external
        view
        returns (uint256 LPTokens, uint256 SNXbalance)
    {
        (LPTokens, SNXbalance) = CurrentWealth();
    }

    function stakeMyShare(uint256 _LPTokenUints, uint256 _SNXtokenUints)
        public
        returns (bool)
    {
        require(
            validateIncomingTokenValues(_LPTokenUints, _SNXtokenUints),
            "SNX Tokens Provided is less than required"
        );
        // basic check
        require(
            (UniswapLiquityTokenAddress.balanceOf(address(this)) == 0),
            "issue:contract is holding some LP Tokens"
        );
        require(
            (_LPTokenUints >= 1000000000),
            "Minimum 1 Gwei LP Tokens required"
        );

        uint256 SNXReq = getSNXRequiredPer_GweiLPT();
        // transfer to this address
        require(
            transferToSelf(_LPTokenUints, SNXReq),
            "issue in trf tokens to self"
        );

        // staking the LP Tokens
        uint256 newtotalLPTokensStaked = SafeMath.add(
            totalLPTokensStaked,
            _LPTokenUints
        );

        Unipool(UnipoolAddress).stake(_LPTokenUints);
        require(
            (Unipool(UnipoolAddress).balanceOf(address(this)) ==
                newtotalLPTokensStaked),
            "issue in reconciling the LP uints staked"
        );
        // updating the internal mapping
        LPTokensSupplied[msg.sender] = SafeMath.add(
            LPTokensSupplied[msg.sender],
            _LPTokenUints
        );

        // updating the in contract varaible for the number of uints staked
        totalLPTokensStaked = newtotalLPTokensStaked;
        mint(msg.sender, _LPTokenUints);
        return (true);
    }

    //@notice: adding buffer only for validation checks
    function validateIncomingTokenValues(uint256 LPT, uint256 SNXT)
        internal
        view
        returns (bool)
    {
        require((quotePrice(LPT)) == SNXT);
        return (true);
    }

    // @notice in the situation where the SNX rewards fall terribly low, compared the LPtokens, the SNX Token wealth per LP token staked will be rounded down to zero using SafeMath
    // @notice hence the compuation below returns the value of the SNX requried per Gwei LP Token
    // @notice the minimum required to enter this contract is also 1 GweiLP Token
    function getSNXRequiredPer_GweiLPT() internal view returns (uint256) {
        (uint256 LPTWealth, uint256 SNXTWealth) = CurrentWealth();
        return ((SNXTWealth.mul(1000000000)).div(LPTWealth));
    }

    function transferToSelf(uint256 LPT, uint256 SNXT) internal returns (bool) {
        UniswapLiquityTokenAddress.transferFrom(msg.sender, address(this), LPT);
        SNXTokenAddress.transferFrom(msg.sender, address(this), SNXT);
        return (true);
    }

    function quotePrice(uint256 _proposedLPTokens)
        public
        view
        returns (uint256 SNXTokensRequired_Per_GweiLPT)
    {
        return (
            SafeMath.mul(
                SafeMath.div(_proposedLPTokens, 1000000000),
                ((SafeMath.mul(getSNXRequiredPer_GweiLPT(), 120).div(100)))
            )
        );
    }

    function getMyStakeOut(uint256 _DZSLTUintsWithdrawing) public {
        // basic check
        require(
            (UniswapLiquityTokenAddress.balanceOf(address(this)) == 0),
            "issue:contract is holding some LP Tokens"
        );
        // checking if the user has already provided number of uints
        uint256 LPTOut = _DZSLTUintsWithdrawing;
        require(
            (LPTokensSupplied[msg.sender]) >= LPTOut &&
                balanceOf[msg.sender] >= _DZSLTUintsWithdrawing,
            "Withdrawing qty more than staked qty"
        );
        // updating the internal mapping to reduce user's qty staked
        LPTokensSupplied[msg.sender] = SafeMath.sub(
            LPTokensSupplied[msg.sender],
            LPTOut
        );
        // updating the in contract varaible for the number of uints staked
        totalLPTokensStaked = SafeMath.sub(totalLPTokensStaked, LPTOut);
        // getting the wealth and price
        uint256 SNX_perGweiLPT = getSNXRequiredPer_GweiLPT();
        uint256 LPTinGwei = SafeMath.div(LPTOut, 1000000000);
        uint256 SNX2beDistributed = SafeMath.mul(SNX_perGweiLPT, LPTinGwei);

        // transferring the LPTokensFirst
        Unipool(UnipoolAddress).withdraw(LPTOut);
        require(
            (UniswapLiquityTokenAddress.balanceOf(address(this))) >= LPTOut,
            "issue in LPTokenBalances"
        );
        UniswapLiquityTokenAddress.transfer(msg.sender, LPTOut);

        if ((SNXTokenAddress.balanceOf(address(this))) >= SNX2beDistributed) {
            SNXTokenAddress.transfer(msg.sender, SNX2beDistributed);
        } else {
            Unipool(UnipoolAddress).getReward();
            require(
                (SNXTokenAddress.balanceOf(address(this)) >= SNX2beDistributed),
                "issue in reconciling the SNX holdigs and rewards"
            );
            SNXTokenAddress.transfer(msg.sender, SNX2beDistributed);
        }

        burn(msg.sender, _DZSLTUintsWithdrawing);

    }

    function CurrentWealth()
        internal
        view
        returns (uint256 LPTokenWealth, uint256 SNXTokenWealth)
    {
        // LP TokenHoldings (since everything will always be staked)
        uint256 LPHoldings = Unipool(UnipoolAddress).balanceOf(address(this));
        // SNX TokenHoldings
        uint256 SNXInHandHoldings = SNXTokenAddress.balanceOf(address(this));
        uint256 SNXOwedByUniPoolContract = Unipool(UnipoolAddress).earned(
            address(this)
        );
        // total wealth return value
        return (
            LPHoldings,
            SafeMath.add(SNXInHandHoldings, SNXOwedByUniPoolContract)
        );
    }

    function mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");
        _beforeTokenTransfer(address(0), account, amount);
        totalSupply = totalSupply.add(amount);
        balanceOf[account] = balanceOf[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    function burn(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: burn from the zero address");
        _beforeTokenTransfer(account, address(0), amount);
        balanceOf[account] = balanceOf[account].sub(
            amount,
            "ERC20: burn amount exceeds balance"
        );
        totalSupply = totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount)
        internal
    {}

    function transfer(address recipient, uint256 amount) public returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function approve(address spender, uint256 amount) public returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount)
        public
        returns (bool)
    {
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            msg.sender,
            allowance[sender][msg.sender].sub(
                amount,
                "ERC20: transfer amount exceeds allowance"
            )
        );
        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount)
        internal
    {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        _beforeTokenTransfer(sender, recipient, amount);
        balanceOf[sender] = balanceOf[sender].sub(
            amount,
            "ERC20: transfer amount exceeds balance"
        );
        balanceOf[recipient] = balanceOf[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        allowance[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

}
