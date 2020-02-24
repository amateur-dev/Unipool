pragma solidity ^0.5.0;

import "./Unipool.sol";

contract iUniPool {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

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

    mapping(address => uint256) LPTokensSupplied;
    uint256 public totalLPTokensStaked;

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

    function stakeMyShare(uint256 _LPTokenUnits) public {
        // basic check
        require(
            (_LPTokenUnits >= 1000000000),
            "less than the minimum required"
        );
        require(
            (UniswapLiquityTokenAddress.allowance(msg.sender, address(this)) >=
                _LPTokenUnits),
            "Allowance Granted to this contract is less"
        );
        require(
            (UniswapLiquityTokenAddress.balanceOf(msg.sender) >= _LPTokenUnits),
            "user balance is less than tokens requested to be staked"
        );

        // finding out the price
        uint256 SNXPerLPToken = getPrice();

        // transfer to this address
        require(
            (
                UniswapLiquityTokenAddress.transferFrom(
                    msg.sender,
                    address(this),
                    _LPTokenUnits
                )
            ),
            "issue in transferring tokens"
        );
        LPTokensSupplied[msg.sender] += _LPTokenUnits;

        // staking the LP Tokens
        uint256 newtotalLPTokensStaked = totalLPTokensStaked;
        newtotalLPTokensStaked += _LPTokenUnits;
        Unipool(UnipoolAddress).stake(_LPTokenUnits);
        require(
            Unipool(UnipoolAddress).balanceOf(address(this)) ==
                newtotalLPTokensStaked
        );
        totalLPTokensStaked = newtotalLPTokensStaked;

    }

    function getPrice() public returns (uint256) {
        uint256 currentSNXHoldings = SNXTokenAddress.balanceOf(address(this));
        uint256 SNXEarned = howMuchHaveIEarned();
        uint256 LPTokensHoldings = totalLPTokensStaked;
        require(
            totalLPTokensStaked ==
                (Unipool(UnipoolAddress).balanceOf(address(this))),
            "error1"
        );
        // updated till here! Working from here.
    }

}
