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
    event ERC20Issued(uint256 qtyIssued);
    event ERC20burned(uint256 qtyBurned);
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

    function getBalance(address _ofWhose) public view returns (uint256) {
        return Unipool(UnipoolAddress).balanceOf(address(_ofWhose));
    }

    // function getBalance() public view returns(uint256) {
    //     return Unipool(UnipoolAddress).balanceOf(address(this));
    // }

    function getRewardOUT() internal returns (uint256) {
        Unipool(UnipoolAddress).getReward();
    }

    function howMuchHaveIEarned() public view returns (uint256) {
        return Unipool(UnipoolAddress).earned(address(this));
    }

    // function getReward() public view returns (uint256) {
    //     return Unipool(UnipoolAddress).earned(address(this));
    // }

    function getMyShareOfLPTokens(address _ofWhose)
        public
        view
        returns (uint256)
    {
        return LPTokensSupplied[_ofWhose];
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
            "less than the minimum required"
        );
        require(
            (UniswapLiquityTokenAddress.balanceOf(msg.sender) >=
                _LPTokenUints &&
                SNXTokenAddress.balanceOf(msg.sender) >= _SNXtokenUints),
            "user balance less than qty requested for staking"
        );
        require(
            (UniswapLiquityTokenAddress.allowance(msg.sender, address(this)) >=
                _LPTokenUints &&
                SNXTokenAddress.allowance(msg.sender, address(this)) >=
                _SNXtokenUints),
            "Allowance not sufficient"
        );

        // transfer to this address
        require(
            transferToSelf(_LPTokenUints, _SNXtokenUints),
            "issue in trf tokens to self"
        );
        // updating the internal mapping
        LPTokensSupplied[msg.sender] = SafeMath.add(
            LPTokensSupplied[msg.sender],
            _LPTokenUints
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

        // updating the in contract varaible for the number of uints staked
        totalLPTokensStaked = newtotalLPTokensStaked;

        // updating the user's balances for the tokens issued
        balanceOf[msg.sender] = balanceOf[msg.sender].add(_LPTokenUints);

        // adding to the total supply of the tokens issued
        totalSupply = totalSupply.add(_LPTokenUints);

        return (true);
    }

    function xxxx(uint256 LPT, uint256 SNXT) internal returns (bool) {
        uint256 SNXRequiredPerDZSLT_inGWei = getSNXRequiredPerLT_inGWei();
        require(
            (
                SafeMath.mul(SafeMath.div(LPT, 1000000000)),
                SNXRequiredPerDZSLT_inGWei
            ) ==
                (SafeMath.div(SNXT, 1000000000))
        );
    }

    function getSNXRequiredPerLT_inGWei() internal returns (uint256) {
        (uint256 LPTWealth, uint256 SNXTWealth) = CurrentWealth();
        return ((SNXTWealth / LPTWealth) / 1000000000);

    }

    function transferToSelf(uint256 LPT, uint256 SNXT) internal returns (bool) {
        UniswapLiquityTokenAddress.transferFrom(msg.sender, address(this), LPT);
        SNXTokenAddress.transferFrom(msg.sender, address(this), SNXT);
        return (true);
    }

    function getMyStakeOut(uint256 _LPTokenUintsWithdrawing) public {
        // basic check
        require(
            (UniswapLiquityTokenAddress.balanceOf(address(this)) == 0),
            "issue:contract is holding some LP Tokens"
        );
        require(
            (LPTokensSupplied[msg.sender]) >= _LPTokenUintsWithdrawing,
            "Withdrawing qty more than staked qty"
        );
        LPTokensSupplied[msg.sender] = SafeMath.sub(
            LPTokensSupplied[msg.sender],
            _LPTokenUintsWithdrawing
        );
        // updating the in contract varaible for the number of uints staked
        totalLPTokensStaked = SafeMath.sub(
            totalLPTokensStaked,
            _LPTokenUintsWithdrawing
        );
        Unipool(UnipoolAddress).exit();
        require(
            (UniswapLiquityTokenAddress.balanceOf(address(this)) ==
                _LPTokenUintsWithdrawing),
            "issue in staking out the LP Token Shares"
        );
        require(
            (
                UniswapLiquityTokenAddress.transfer(
                    msg.sender,
                    _LPTokenUintsWithdrawing
                )
            ),
            "issue in transferring out the LP Tokens"
        );
        require(
            (SNXTokenAddress.transfer(msg.sender, _LPTokenUintsWithdrawing)),
            "issue in transferring out the LP Tokens"
        );

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

    // function getPrice() public returns (uint256) {
    //     uint256 currentSNXHoldings = SNXTokenAddress.balanceOf(address(this));
    //     uint256 SNXEarned = howMuchHaveIEarned();
    //     uint256 LPTokensHoldings = totalLPTokensStaked;
    //     require(
    //         totalLPTokensStaked ==
    //             (Unipool(UnipoolAddress).balanceOf(address(this))),
    //         "error1"
    //     );
    //     // updated till here! Working from here.
    // }

}
