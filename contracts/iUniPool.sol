pragma solidity ^0.5.0;

import "./Unipool.sol";
import "./iUniswapExchangeContract.sol";

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
    IERC20 public constant sETH_LP_TokenAddress = IERC20(
        0xe9Cf7887b93150D4F2Da7dFc6D502B216438F244
    );
    IERC20 public constant SNXTokenAddress = IERC20(
        0xC011a73ee8576Fb46F5E1c5751cA3B9Fe0af2a6F
    );
    IERC20 public constant SNXUniSwapTokenAddress = IERC20(
        0xe3385df5b47687405A02Fc24322DeDb7df381852
    );
    IERC20 public constant sETHUniSwapTokenAddress = IERC20(
        0xd3EBA712988df0F8A7e5073719A40cE4cbF60b33
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
        approve_Addresses();
    }

    function approve_Addresses() internal {
        IERC20(sETH_LP_TokenAddress).approve(UnipoolAddress, ((2 ^ 256) - 1));
        IERC20(SNXTokenAddress).approve(
            address(SNXUniSwapTokenAddress),
            ((2 ^ 256) - 1)
        );
        IERC20(SNXTokenAddress).approve(
            address(SNXUniSwapTokenAddress),
            ((2 ^ 256) - 1)
        );
        IERC20(sETHTokenAddress).approve(
            address(sETHUniSwapTokenAddress),
            ((2 ^ 256) - 1)
        );

    }

    // reader functions

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

    // action functions
    function stakeMyShare(uint256 _LPTokenUints) public returns (uint256) {
        // @this is to confirm that all LP tokens are always staked
        require(
            (sETH_LP_TokenAddress.balanceOf(address(this)) == 0),
            "issue:contract is holding some LP Tokens"
        );

        // dipesh TODO: to check if this is required
        require(
            (_LPTokenUints >= 1000000000),
            "Minimum 1 Gwei LP Tokens required"
        );

        // transfer to this address
        require(transferToSelf(_LPTokenUints), "issue in trf tokens to self");

        // FIXME: maybe the mapping of LPTokensSupplied is not required
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
        issueTokens(msg.sender, _LPTokenUints);
        return (true);
    }

    function issueTokens(address toWhom, uint256 howMuchLPStaked)
        internal
        returns (uint256 tokensIssued)
    {
        if (totalLPTokensStaked == 0) {
            mint(toWhom, howMuchLPStaked);
            return (howMuchLPStaked);
        } else {
            uint256 priceInLP = getPricePerToken();
            uint256 qty2bminted = (howMuchLPStaked).div(priceInLP);
            mint(toWhom, qty2bminted);
            return (howMuchLPStaked);

        }
    }

    function getPricePerToken() internal returns (uint256 LP_Per_Token) {
        if (totalLPTokensStaked == 0) {
            return (1);
        } else {
            // FIXME:
            simulate_reBalance();
            require(
                totalLPTokensStaked ==
                    Unipool(UnipoolAddress).balanceOf(address(this)),
                "issue in LPStaked"
            );
            return ((totalLPTokensStaked).div(totalSupply));
        }
    }

    // @notice in the situation where the SNX rewards fall terribly low, compared the LPtokens, the SNX Token wealth per LP token staked will be rounded down to zero using SafeMath
    // @notice hence the compuation below returns the value of the SNX requried per Gwei LP Token
    // @notice the minimum required to enter this contract is also 1 GweiLP Token
    // function getSNXRequiredPer_GweiLPT() internal view returns (uint256) {
    //     (uint256 LPTWealth, uint256 SNXTWealth) = CurrentWealth();
    //     return ((SNXTWealth.mul(1000000000)).div(LPTWealth));
    // }

    function transferToSelf(uint256 LPT) internal returns (bool) {
        sETH_LP_TokenAddress.transferFrom(msg.sender, address(this), LPT);
        return (true);
    }

    // TODO: need to do this
    function TokenValue(uint256 _tokenQTY)
        public
        view
        returns (uint256 expectedLPTokens)
    {
        return (
            SafeMath.mul(
                SafeMath.div(_proposedLPTokens, 1000000000),
                ((SafeMath.mul(getSNXRequiredPer_GweiLPT(), 120).div(100)))
            )
        );
    }

    function getMyStakeOut(uint256 _tokenQTY) public {
        require(balanceOf[msg.sender] >= _tokenQTY, "Withdrawing qty invalid");
        uint256 LPT2bReturned = TokenValue(_tokenQTY);

        // FIXME: maybe the mapping of LPTokensSupplied is not required

        // updating the internal mapping to reduce user's qty staked
        LPTokensSupplied[msg.sender] = SafeMath.sub(
            LPTokensSupplied[msg.sender],
            LPT2bReturned
        );

        // updating the in contract varaible for the number of uints staked
        totalLPTokensStaked = SafeMath.sub(totalLPTokensStaked, LPT2bReturned);

        // transferring the LPTokensFirst
        Unipool(UnipoolAddress).withdraw(LPT2bReturned);
        sETH_LP_TokenAddress.transfer(msg.sender, LPT2bReturned);

        //FIXME:
        burn(msg.sender, _DZSLTUintsWithdrawing);

    }

    function reBalance() public returns (uint256 LPTokenWealth) {
        // LP TokenHoldings (since everything will always be staked)
        uint256 LPHoldings_priorConversion = Unipool(UnipoolAddress).balanceOf(
            address(this)
        );
        require(
            (totalLPTokensStaked == LPHoldings_priorConversion),
            "issue in LP Tokens Staked"
        );
        // claim reward
        Unipool(UnipoolAddress).getReward();
        // SNX TokenHoldings
        uint256 SNXInHandHoldings = SNXTokenAddress.balanceOf(address(this));

        if (SNXInHandHoldings != 0) {
            uint256 LPJustReceived = convertSNXtoLP(SNXInHandHoldings);
            Unipool(UnipoolAddress).stake(LPJustReceived);
            totalLPTokensStaked += LPJustReceived;
            return (LPHoldings_priorConversion.add(LPJustReceived));
        }

        return (LPHoldings_priorConversion);
    }

    function convertSNXtoLP(uint256 SNXQty)
        internal
        returns (uint256 LPReceived)
    {
        uint256 con_po = SafeMath.div(SNXQty, 2).add(100);
        uint256 non_con_po = SafeMath.sub(SNXQty, con_po);
        uint256 con_po_seth = UniswapExchangeInterface(
            address(SNXUniSwapTokenAddress)
        )
            .tokenToTokenSwapInput(
            con_po,
            min_tokens(
                (min_eth(con_po, address(SNXUniSwapTokenAddress)).mul(99)).div(
                    100
                ),
                address(sETHUniSwapTokenAddress)
            ),
            (min_eth(con_po, address(SNXUniSwapTokenAddress)).mul(99).div(100)),
            now.add(300),
            sETHTokenAddress
        );
        uint256 non_con_po_eth = UniswapExchangeInterface(
            address(SNXUniSwapTokenAddress)
        )
            .tokenToEthSwapInput(
            non_con_po,
            (min_eth(con_po, address(SNXUniSwapTokenAddress).mul(99).div(100))),
            now.add(300)
        );
        return
            new_LPT = UniswapExchangeInterface(address(sETH_LP_TokenAddress))
                .addLiquidity
                .value(non_con_po_eth)(
                1,
                getMaxTokens(
                    address(sETH_LP_TokenAddress),
                    sETHTokenAddress,
                    non_con_po_eth
                ),
                now.add(300)
            );
    }

    function getMaxTokens(address uniExchAdd, IERC20 ERC20Add, uint256 value)
        internal
        view
        returns (uint256)
    {
        uint256 contractBalance = address(_UniSwapExchangeContractAddress)
            .balance;
        uint256 eth_reserve = SafeMath.sub(contractBalance, _value);
        uint256 token_reserve = _ERC20TokenAddress.balanceOf(
            _UniSwapExchangeContractAddress
        );
        uint256 token_amount = SafeMath.div(
            SafeMath.mul(_value, token_reserve),
            eth_reserve
        ) +
            1;
        return token_amount;
    }

    function min_eth(uint256 tokenQTY, address uniExchAdd)
        internal
        returns (uint256)
    {
        return
            UniswapExchangeInterface(uniExchAdd).getTokenToEthInputPrice(
                tokenQTY
            );
    }

    function min_tokens(uint256 ethAmt, address uniExchAdd)
        internal
        returns (uint256)
    {
        return
            UniswapExchangeInterface(uniExchAdd).getEthToTokenInputPrice(
                ethAmt
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
