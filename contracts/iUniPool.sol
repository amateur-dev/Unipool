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

    function getReward(address _ofWhose) public view returns (uint256) {
        return Unipool(UnipoolAddress).earned(address(_ofWhose));
    }

    // function getReward() public view returns (uint256) {
    //     return Unipool(UnipoolAddress).earned(address(this));
    // }

}
