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
        sETH_LP_TokenAddress.approve(UnipoolAddress, ((2**256) - 1));
        SNXTokenAddress.approve(
            address(SNXUniSwapTokenAddress),
            ((2**256) - 1)
        );
        IERC20(sETHTokenAddress).approve(
            address(sETH_LP_TokenAddress),
            ((2**256) - 1)
        );

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
     * @dev Returs the amount of LP required to stake / transfer to buy 1 DZLT token
     */
    function PriceToStakeNow() external view returns (uint256) {
        if (totalSupply > 0) {
            if (Unipool(UnipoolAddress).earned(address(this)) > 0) {
                uint256 eth4SNX = min_eth(
                    (Unipool(UnipoolAddress).earned(address(this))),
                    address(SNXUniSwapTokenAddress)
                );
                uint256 eth_reserves = address(sETH_LP_TokenAddress).balance;
                uint256 LP_total_supply = sETH_LP_TokenAddress.totalSupply();
                uint256 LP_for_stake = (eth4SNX.div(2).mul(LP_total_supply))
                    .div(eth_reserves);
                return
                    (LP_for_stake).add(howMuchHasThisContractStaked()).div(
                        totalSupply
                    );
            } else {
                return (howMuchHasThisContractStaked()).div(totalSupply);
            }

        } else {
            return (1);
        }

    }

    // action functions
    function stakeMyShare(uint256 _LPTokenUints) public returns (uint256) {
        // transfer to this address
        sETH_LP_TokenAddress.transferFrom(
            msg.sender,
            address(this),
            _LPTokenUints
        );

        LPTokensSupplied[msg.sender] = SafeMath.add(
            LPTokensSupplied[msg.sender],
            _LPTokenUints
        );

        Unipool(UnipoolAddress).stake(_LPTokenUints);

        uint256 tokens = issueTokens(msg.sender, _LPTokenUints);

        // updating the in contract varaible for the number of uints staked
        totalLPTokensStaked += _LPTokenUints; //Consider using SafeMath.add(totalLPTokensStaked, _LPTokenUints);
        return (tokens);
    }

    function issueTokens(address toWhom, uint256 howMuchLPStaked)
        internal
        returns (uint256 tokensIssued)
    {
        uint256 tokens2bIssued = getPricePerToken(true).mul(howMuchLPStaked);
        mint(toWhom, tokens2bIssued);
        return tokens2bIssued;
    }

    function getPricePerToken(bool enter)
        internal
        returns (uint256 LP_Per_Token)
    {
        if (totalLPTokensStaked == 0 && totalSupply == 0) {
            return (1);
        } else {
            uint256 totalLPs = reBalance(enter);
            return totalSupply.div(totalLPs);

            // return ((totalLPTokensStaked).div(totalSupply));

        }
    }

    function getMyStakeOut(uint256 _tokenQTY) public {
        require(balanceOf[msg.sender] >= _tokenQTY, "Withdrawing qty invalid");
        uint256 LPs2bRedemeed = _tokenQTY.div(getPricePerToken(false));
        uint256 LPsInHand = sETH_LP_TokenAddress.balanceOf(address(this));
        if (LPs2bRedemeed > LPsInHand) {
            uint256 LPsShortOf = LPs2bRedemeed.sub(LPsInHand);
            Unipool(UnipoolAddress).withdraw(LPsShortOf);
        }
        sETH_LP_TokenAddress.transfer(msg.sender, LPs2bRedemeed);
        // updating the internal mapping to reduce user's qty staked
        LPTokensSupplied[msg.sender] = SafeMath.sub(
            LPTokensSupplied[msg.sender],
            LPs2bRedemeed
        );
        totalLPTokensStaked -= LPs2bRedemeed;
        burn(msg.sender, _tokenQTY);
    }

    function reBalance(bool enter) public returns (uint256 LPTokenWealth) {
        // LP TokenHoldings (since everything will always be staked)
        uint256 LPHoldings_b4Rebalance = howMuchHasThisContractStaked();
        // uint256 SNXEarned = howMuchHasThisContractEarned();

        // claim reward
        Unipool(UnipoolAddress).getReward();

        // SNX TokenHoldings
        uint256 SNXInHandHoldings = SNXTokenAddress.balanceOf(address(this));

        if (SNXInHandHoldings > 0) {
            uint256 LPJustReceived = convertSNXtoLP(SNXInHandHoldings);
            if (enter) {
                Unipool(UnipoolAddress).stake(LPJustReceived);
                totalLPTokensStaked += LPJustReceived;

            }
            return (LPHoldings_b4Rebalance.add(LPJustReceived));
        }

    }

    function convertSNXtoLP(uint256 SNXQty)
        internal
        returns (uint256 LPReceived)
    {
        uint256 con_po = SafeMath.div(SNXQty, 2).add(1000);
        uint256 non_con_po = SafeMath.sub(SNXQty, con_po);
        UniswapExchangeInterface(address(SNXUniSwapTokenAddress))
            .tokenToTokenSwapInput(
            con_po,
            min_tokens(
                (min_eth(con_po, address(SNXUniSwapTokenAddress)).mul(99)).div(
                    100
                ),
                address(sETHTokenAddress)
            ),
            (min_eth(con_po, address(SNXUniSwapTokenAddress)).mul(99).div(100)),
            now.add(300),
            address(sETHTokenAddress)
        );
        uint256 non_con_po_eth = UniswapExchangeInterface(
            address(SNXUniSwapTokenAddress)
        )
            .tokenToEthSwapInput(
            non_con_po,
            (
                (
                    min_eth(con_po, address(SNXUniSwapTokenAddress))
                        .mul(99)
                        .div(100)
                )
            ),
            now.add(300)
        );
        return
            UniswapExchangeInterface(address(sETH_LP_TokenAddress))
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

    // function _beforeTokenTransfer(address from, address to, uint256 amount)
    //     internal
    // {}

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

}
