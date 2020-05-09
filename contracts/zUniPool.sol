pragma solidity ^0.5.0;

import "./Unipool.sol";
import "./iUniswapExchangeContract.sol";

contract zUniPool is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // --- ERC20 Data ---
    string public constant name = "zUNIT";
    string public constant symbol = "zUNIT";
    string public constant version = "1";
    uint8 public constant decimals = 18;
    uint256 public totalSupply;

    /**
     - Need to check impact of Uniswap V2,  will we need to deploy a v2 or new version of DZSLT
     due to changes in sETH_LP_TokenAddress and potentially a new version of SNXUniswapTokenAddress?
    */
    address public constant UnipoolAddress = 0x48D7f315feDcaD332F68aafa017c7C158BC54760;
    IERC20 public constant sETHTokenAddress = IERC20(
        0x5e74C9036fb86BD7eCdcb084a0673EFc32eA31cb
    );
    IERC20 public constant sETH_LP_TokenAddress = IERC20(
        0xe9Cf7887b93150D4F2Da7dFc6D502B216438F244
    );
    IERC20 public constant SNXTokenAddress = IERC20(
        0xC011a73ee8576Fb46F5E1c5751cA3B9Fe0af2a6F
    );
    IERC20 public constant SNXUniSwapTokenAddress = IERC20(
        0x3958B4eC427F8fa24eB60F42821760e88d485f7F
    );

    uint256 public totalLPTokensStaked;

    bool public stopped;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    mapping(address => bool) public allowedAddress;

    // events
    event LPTokensStaked(address indexed staker, uint256 qtyStaked);
    event LPTokensWithdrawn(address indexed leaver, uint256 qtyWithdrawn);
    event Approval(address indexed src, address indexed guy, uint256 wad);
    event Transfer(address indexed src, address indexed dst, uint256 wad);
 
    // testing events
    event internall(string, uint256);

    modifier stopInEmergency {
        if (stopped) {
            revert("Temporarily Paused");
        } else {
            _;
        }
    }

    modifier allowedToStake {
        require(allowedAddress[msg.sender], "you are not allowed to stake through this contract");
        _;
    }

    function allowTheAddress(address _permittedAccount) public onlyOwner {
        allowedAddress[_permittedAccount] = true;
    }

    function removeTheAddress(address _removalAccount) public onlyOwner {
        require(balanceOf[_removalAccount] == 0, "this address still holds some tokens and cannot be removed");
        allowedAddress[_removalAccount] = false;
    }

    constructor() public {
        approve_Addresses();
        stopped = false;
    }

    function approve_Addresses() public {
        sETH_LP_TokenAddress.approve(UnipoolAddress, ((2**256) - 1));
        SNXTokenAddress.approve(
            address(SNXUniSwapTokenAddress),
            ((2**256) - 1)
        );
        sETHTokenAddress.approve(address(sETH_LP_TokenAddress), ((2**256) - 1));
    }

    // reader functions

    function howMuchHasThisContractStaked()
        public
        view
        returns (uint256 LPTokens)
    {
        return Unipool(UnipoolAddress).balanceOf(address(this));
    }

    function howMuchHasThisContractEarned()
        public
        view
        returns (uint256 SNXEarned)
    {
        return Unipool(UnipoolAddress).earned(address(this));
    }

    /**
     * @dev Returs the amount of LP redemeemable / to be staked for a given quantity of zUNI
     */
    function howMuchIszUNIWorth(uint256 _zUNIinWEI)
        external
        view
        returns (uint256)
    {
        if (totalSupply > 0) {
            if (
                Unipool(UnipoolAddress).earned(address(this)) > 0.000005 ether
            ) {
                uint256 eth4SNX = min_eth(
                    (Unipool(UnipoolAddress).earned(address(this))),
                    address(SNXUniSwapTokenAddress)
                );
                uint256 maxTokens = getMaxTokens(
                    address(sETH_LP_TokenAddress),
                    sETHTokenAddress,
                    ((eth4SNX).mul(4985)).div(10000)
                );
                uint256 notinalLP = totalLPTokensStaked.add(maxTokens);
                return (((_zUNIinWEI).mul(notinalLP)).div(totalSupply));
            } else {
                return (
                    ((_zUNIinWEI).mul(totalLPTokensStaked)).div(totalSupply)
                );
            }
        } else {
            return (1);
        }

    }

    // action functions
    function stakeMyShare(uint256 _LPTokenUints) public allowedToStake stopInEmergency returns (uint256) {
        // transfer to this address
        sETH_LP_TokenAddress.transferFrom(
            msg.sender,
            address(this),
            _LPTokenUints
        );

        uint256 tokens = issueTokens(msg.sender, _LPTokenUints);
        emit internall("tokens", tokens);

        Unipool(UnipoolAddress).stake(_LPTokenUints);

        totalLPTokensStaked = totalLPTokensStaked.add(_LPTokenUints);
        return (tokens);
    }

    function issueTokens(address toWhom, uint256 howMuchLPStaked)
        internal
        returns (uint256 tokensIssued)
    {
        (uint256 totalLPs, uint256 totalzUNIs) = getDetails(true);
        uint256 tokens2bIssued = (howMuchLPStaked.mul(totalzUNIs)).div(
            totalLPs
        );
        emit internall("howMuchLPStaked", howMuchLPStaked);
        emit internall("tokens2bIssued", tokens2bIssued);
        mint(toWhom, tokens2bIssued);
        return tokens2bIssued;
    }

    function getDetails(bool enter)
        internal
        returns (uint256 totalLPs, uint256 totalzUNIs)
    {
        if (totalSupply == 0) {
            emit internall("entering phase 1", 0);
            return (1, 1);
        } else {
            emit internall("entering phase 2", 1);
            return (reBalance(enter), totalSupply);
        }
    }
    /* @dev: it does not make economical sense to claim reward if the SNX 
    / earned is less than 0.000005; considering the price of SNX at the time 
    / of writing this contract
    */
    function reBalance(bool enter) internal returns (uint256 LPTokenWealth) {
        

        if (howMuchHasThisContractEarned() > 0.000005 ether) {
            emit internall(
                "Earnings more than the threshold",
                howMuchHasThisContractEarned()
            );
            Unipool(UnipoolAddress).getReward();
            uint256 SNXInHandHoldings = SNXTokenAddress.balanceOf(
                address(this)
            );
            emit internall("Claiming Reward", SNXInHandHoldings);
            uint256 LPJustReceived = convertSNXtoLP(SNXInHandHoldings);
            emit internall("LPJustReceived", LPJustReceived);
            if (enter) {
                Unipool(UnipoolAddress).stake(LPJustReceived);
                totalLPTokensStaked = totalLPTokensStaked.add(LPJustReceived);
                emit internall("totalLPTokensStaked", totalLPTokensStaked);
                return (totalLPTokensStaked);
            } else {
                return (totalLPTokensStaked.add(LPJustReceived));
            }

        } else {
            return (totalLPTokensStaked);
        }
    }

    function reBalanceContractWealth() public returns (uint256 LPTokenWealth) {
        reBalance(false);
    }

    function convertSNXtoLP(uint256 SNXQty)
        internal
        returns (uint256 LPReceived)
    {
        uint256 SNX2BcETH = SafeMath.mul(SNXQty, 4985).div(10000);
        uint256 SNX2BcSETH = SafeMath.sub(SNXQty, SNX2BcETH);

        uint256 ETHfromSNX = UniswapExchangeInterface(
            address(SNXUniSwapTokenAddress)
        )
            .tokenToEthSwapInput(
            SNX2BcETH,
            (
                (
                    min_eth(SNX2BcETH, address(SNXUniSwapTokenAddress))
                        .mul(995)
                        .div(1000)
                )
            ),
            now.add(300)
        );

        // converting a portion of the SNX to sETH for the purpose of adding liquidity
        UniswapExchangeInterface(address(SNXUniSwapTokenAddress))
            .tokenToTokenSwapInput(
            SNX2BcSETH,
            min_tokens(
                (min_eth(SNX2BcSETH, address(SNXUniSwapTokenAddress)).mul(995))
                    .div(1000),
                address(sETH_LP_TokenAddress)
            ),
            (
                min_eth(SNX2BcSETH, address(SNXUniSwapTokenAddress))
                    .mul(995)
                    .div(1000)
            ),
            now.add(300),
            address(sETHTokenAddress)
        );

        // adding liquidity
        uint256 LPU = UniswapExchangeInterface(address(sETH_LP_TokenAddress))
            .addLiquidity
            .value(ETHfromSNX)(
            1,
            getMaxTokens(
                address(sETH_LP_TokenAddress),
                sETHTokenAddress,
                ETHfromSNX
            ),
            now.add(300)
        );

        // converting the balance sETH to SNX

        UniswapExchangeInterface(address(sETH_LP_TokenAddress))
            .tokenToTokenSwapInput(
            (sETHTokenAddress.balanceOf(address(this))),
            min_tokens(
                (
                    min_eth(
                        (sETHTokenAddress.balanceOf(address(this))),
                        address(sETH_LP_TokenAddress)
                    )
                        .mul(995)
                        .div(1000)
                ),
                address(SNXUniSwapTokenAddress)
            ),
            (
                min_eth(
                    (sETHTokenAddress.balanceOf(address(this))),
                    address(sETH_LP_TokenAddress)
                )
                    .mul(995)
                    .div(1000)
            ),
            now.add(300),
            address(SNXTokenAddress)
        );

        return LPU;
    }

    function getMaxTokens(address uniExchAdd, IERC20 ERC20Add, uint256 value)
        internal
        view
        returns (uint256)
    {
        uint256 contractBalance = address(uniExchAdd).balance;
        uint256 eth_reserve = SafeMath.sub(contractBalance, value);
        uint256 token_reserve = ERC20Add.balanceOf(uniExchAdd);
        uint256 token_amount = SafeMath.div(
            SafeMath.mul(value, token_reserve),
            eth_reserve
        ) +
            1;
        return token_amount;
    }

    function min_eth(uint256 tokenQTY, address uniExchAdd)
        internal
        view
        returns (uint256)
    {
        return
            UniswapExchangeInterface(uniExchAdd).getTokenToEthInputPrice(
                tokenQTY
            );
    }

    function min_tokens(uint256 ethAmt, address uniExchAdd)
        internal
        view
        returns (uint256)
    {
        return
            UniswapExchangeInterface(uniExchAdd).getEthToTokenInputPrice(
                ethAmt
            );
    }

    function getMyStakeOut(uint256 _tokenQTY)
        public stopInEmergency
        returns (uint256 LPTokensReleased)
    {
        require(balanceOf[msg.sender] >= _tokenQTY, "Withdrawing qty invalid");
        (uint256 totalLPs, uint256 totalzUNIs) = getDetails(false);
        uint256 LPs2bRedemeed = (_tokenQTY.mul(totalLPs)).div(totalzUNIs);
        uint256 LPsInHand = sETH_LP_TokenAddress.balanceOf(address(this));
        if (LPs2bRedemeed > LPsInHand) {
            uint256 LPsShortOf = LPs2bRedemeed.sub(LPsInHand);
            Unipool(UnipoolAddress).withdraw(LPsShortOf);
            sETH_LP_TokenAddress.transfer(msg.sender, LPs2bRedemeed);
            totalLPTokensStaked = totalLPTokensStaked.sub(LPsShortOf);
        } else {
            sETH_LP_TokenAddress.transfer(msg.sender, LPs2bRedemeed);
            uint256 leftOverLPs = sETH_LP_TokenAddress.balanceOf(address(this));
            if (leftOverLPs > 0) {
                Unipool(UnipoolAddress).stake(leftOverLPs);
                // FIXME: This formula is not correct
                totalLPTokensStaked = totalLPTokensStaked.add(leftOverLPs);
            }
        }
        burn(msg.sender, _tokenQTY);
        return (LPs2bRedemeed);
    }

    function mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");
        // _beforeTokenTransfer(address(0), account, amount);
        totalSupply = totalSupply.add(amount);
        balanceOf[account] = balanceOf[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    function burn(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: burn from the zero address");
        // _beforeTokenTransfer(account, address(0), amount);
        balanceOf[account] = balanceOf[account].sub(
            amount,
            "ERC20: burn amount exceeds balance"
        );
        totalSupply = totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

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
        // _beforeTokenTransfer(sender, recipient, amount);
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

    function() external payable {
        emit internall("got cash", msg.value);
    }

    // governance functions

    function getRewardOut() public onlyOwner returns (uint totalSNXReward) {
        require(stopped, "first pause the contract");
        Unipool(UnipoolAddress).getReward();
        emit internall("Owner Took out reward", SNXTokenAddress.balanceOf(
                address(this)
            ));
        inCaseTokengetsStuck(SNXTokenAddress);
        return (SNXTokenAddress.balanceOf(address(this)));
    }

    function withdrawAllStaked() public onlyOwner returns (uint totalStakedUintsWithdrawn) {
        uint stakedUints = Unipool(UnipoolAddress).balanceOf(address(this));
        Unipool(UnipoolAddress).withdraw(stakedUints);
        inCaseTokengetsStuck(sETH_LP_TokenAddress);
        emit internall("total staked uints taken out", stakedUints);
        return (stakedUints);
    }

    // - to kill the contract
    function destruct() public onlyOwner {
        address owner_ = owner();
        selfdestruct(address(uint160(owner_)));
    }

    // - to withdraw any ETH balance sitting in the contract
    function withdraw() public onlyOwner {
        address owner_ = owner();
        address(uint160(owner_)).transfer(address(this).balance);
    }

    // - to Pause the contract
    function toggleContractActive() public onlyOwner {
        stopped = !stopped;
    }

    function inCaseTokengetsStuck(IERC20 _TokenAddress) public onlyOwner {
        address owner_ = owner();
        uint256 qty = _TokenAddress.balanceOf(address(this));
        _TokenAddress.transfer(owner_, qty);
    }

}
