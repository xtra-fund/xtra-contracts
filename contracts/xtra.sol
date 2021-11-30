// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IPancakeFactory.sol";
import "./interfaces/IPancakePair.sol";
import "./XtraStaking.sol";
import "./XtraVesting.sol";
import "./XtraInvesting.sol";

/// @title Xtra Fund Contract
/// @author bs
/// @notice Contract was not audited
contract Xtra is
    ERC20,
    ERC20Burnable,
    Ownable,
    XtraStaking,
    XtraVesting,
    XtraInvesting
{
    /// ----- VARIABLES ----- ///

    /// Pool names
    uint256 internal constant POOL_SEED = 1;
    uint256 internal constant POOL_PRESALE = 2;
    uint256 internal constant POOL_PRESALE2 = 3;
    uint256 internal constant POOL_TEAM = 4;

    /// Max supply
    uint256 internal _seed_tokens = 1000000000 * 10**18; //1 mlrd
    uint256 internal _presale_tokens = 2000000000 * 10**18; //2 mlrd
    uint256 internal _presale2_tokens = 1500000000 * 10**18; //1,5 mlrd
    uint256 internal _sale_tokens = 1500000000 * 10**18; //1,5 mlrd
    uint256 internal _team_tokens = 2000000000 * 10**18; //2 mlrd
    uint256 internal _lp_tokens = 2000000000 * 10**18; //2 mlrd
    uint256 internal _loan_fund = 10000000000 * 10**18; //10 mlrd

    /// Token price
    uint256 internal _initialTokenPrice = 10**5;

    /// Test only variable
    // uint256 _testTokenPrice = 10**6; //TODO: Delete on prod

    /// Pancakeswap addresses
    address internal _pancakeFactoryAddress;
    address internal _stableCoinAddress;

    /// Bep20 allocation token address
    address internal _allocationTokenAddress;

    /// ----- CONSTRUCTOR ----- ///
    constructor(
        address _psFactoryAddress,
        address _stableAddress,
        address _allocationToken
    ) ERC20("Xtra Fund Token", "XTRA") {
        _pancakeFactoryAddress = _psFactoryAddress;
        _stableCoinAddress = _stableAddress;
        _allocationTokenAddress = _allocationToken;
        _mint(address(this), 20000000000 ether);
    }

    /// ----- VIEWS ----- ///
    ///@notice Returns data with token pools information
    ///@return 0 mintedTokens - Sum of minted tokens
    ///@return 1 totalStaked - Sum of staked tokens
    ///@return 2 seedTokens - Remaining seed tokens
    ///@return 3 presaleTokens - Remaining presale tokens
    ///@return 4 presale2Tokens - Remaining presale round 2 tokens
    ///@return 5 saleTokens - Remaining sale tokens
    ///@return 6 teamTokens - Remaining team tokens
    ///@return 7 lpTokens - Remaining liqudity pool tokens
    ///@return 8 loanTokens - Remaining loan fund tokens
    ///@return 9 xtraTokens - Xtra fund tokens (can be max minted)
    ///@return 10 totalVestings - Sum of tokens in vestings
    ///@return 11 totalInvests - Sum of not activated tokens
    function getTokenStats()
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        return (
            totalSupply(),
            _totalStaked,
            _seed_tokens,
            _presale_tokens,
            _presale2_tokens,
            _sale_tokens,
            _team_tokens,
            _lp_tokens,
            _loan_fund,
            _xtra_fund,
            _totalVestings,
            _totalInvestitions
        );
    }

    ///@notice Returns token price
    ///@return tokenPrice - price of token
    function getTokenPrice() external view returns (uint256 tokenPrice) {
        return _getTokenPrice();
    }

    ///@notice Calculates return for selected staking slot with actual token price. If isFromXtra is true xtraAmount will be minted from xtra fund to staker address. Else xtra amount will be burn and added to xtra fund.
    ///@param _stakerAddress - Address of staker
    ///@param _slot - Slot of stake
    ///@return 0 userAmount - amount in xtra tokens returns to user
    ///@return 1 xtraAmount - amount in xtra tokens from/to xtra fund
    ///@return 2 isFromXtra - true if tokens need to be minted from xtra fund. false if tokens will burn and added to xtra fund
    function calculateWithdraw(address _stakerAddress, uint256 _slot)
        external
        view
        returns (
            uint256,
            uint256,
            bool
        )
    {
        (
            uint256 _userAmount,
            uint256 _xtraAmount,
            bool _isFromXtra
        ) = _calculateWithdraw(_stakerAddress, _slot, _getTokenPrice());
        return (_userAmount, _xtraAmount, _isFromXtra);
    }

    ///@notice Calculates liqudation return for selected staking slot with actual token price. The method is used when unstake date has not yet arrived.
    ///@param _stakerAddress - Address of staker
    ///@param _slot - Slot of stake
    ///@return 0 toReturn - tokens returns to staker
    ///@return 1 toBurn - tokens will be burnt
    function calculateLiquidationReturn(address _stakerAddress, uint256 _slot)
        external
        view
        returns (uint256, uint256)
    {
        (uint256 _toReturn, uint256 _toBurn) = _calculateLiquidationReturn(
            _stakerAddress,
            _slot,
            _getTokenPrice()
        );
        return (_toReturn, _toBurn);
    }

    ///@notice Returns address stats.
    ///@param _address - Address to check
    ///@return 0 balance - Token balance of address (available, free tokens)
    ///@return 1 sumStaked - Sum of all staked tokens of address
    ///@return 2 investNum - Number of invest slots of address
    ///@return 3 vestingNum - Number of vesting slots of address
    ///@return 4 stakesNum - Number of stake slots of address
    function userNums(address _address)
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        return (
            balanceOf(_address),
            _sumStakedByUser(_address),
            _investitionsOfUser[_address],
            _vestingsOfUser[_address],
            _stakesOfUser[_address]
        );
    }

    /// ----- OWNERS FUNCTIONS ----- ///
    ///@notice Adding investors to smart contract. Executable by contract owner only.
    ///@dev Contract owner only. _stakingStartDate must be initialized first.
    ///@param _addresses - Array of investors addresses
    ///@param _amounts - Array of amount to add
    ///@param _pools - Array of invest pools (POOL_SEED, POOL_PRESALE etc)
    function addInvestors(
        address[] memory _addresses,
        uint256[] memory _amounts,
        uint256[] memory _pools
    ) external onlyOwner {
        require(_stakingStartDate > 0, "Initialize date first");
        _addInvestors(_addresses, _amounts, _pools);
    }

    ///@notice Distribute(mint) sale tokens. Executable by contract owner only.
    ///@dev Contract owner only. Cant withdraw more than _sale_tokens.
    ///@param _receiverAddress - Address which recieves sale tokens
    function distributeSale(address _receiverAddress) external onlyOwner {
        require(_sale_tokens > 0, "Cant distribute more than cap");
        _transfer(address(this), _receiverAddress, _sale_tokens);
        _sale_tokens = 0;
    }

    ///@notice Distribute(mint) lp tokens. Executable by contract owner only.
    ///@dev Contract owner only. Cant withdraw more than _lp_tokens.
    ///@param _receiverAddress - Address which recieves tokens
    ///@param _amount - Amount be minted
    function distributeLPTokens(uint256 _amount, address _receiverAddress)
        external
        onlyOwner
    {
        require(_lp_tokens - _amount >= 0, "Cant distribute more than cap");
        _lp_tokens -= _amount;
        _transfer(address(this), _receiverAddress, _amount);
    }

    ///@notice Distribute(mint) loan fund tokens. Executable by contract owner only.
    ///@dev Contract owner only. Cant withdraw more than _loan_fund.
    ///@param _receiverAddress - Address which recieves tokens
    ///@param _amount - Amount be minted
    function distributeLoanFund(uint256 _amount, address _receiverAddress)
        external
        onlyOwner
    {
        require(_loan_fund - _amount >= 0, "Cant distribute more than cap");
        //TODO once per quartal
        _loan_fund -= _amount;
        _transfer(address(this), _receiverAddress, _amount);
    }

    /// ----- INTERNAL FUNCTIONS ----- ///
    ///@dev Returns actial token price from pancakeswap pair
    ///@return token price
    function _getTokenPrice() internal view returns (uint256) {
        address pairAddress = IPancakeFactory(_pancakeFactoryAddress).getPair(
            address(this),
            _stableCoinAddress
        );
        IPancakePair pair = IPancakePair(pairAddress);
        (uint256 Res0, uint256 Res1, ) = pair.getReserves();
        if (pair.token0() == address(this)) {
            return ((Res1 * 10**8) / Res0);
        } else return ((Res0 * 10**8) / Res1);
        // return (_testTokenPrice);
    }

    /// ----- TEST FUNCTIONS ----- ///
    //TODO: remove before prod
    // function setTokenPrice(uint256 _newPrice) external {
    //     _testTokenPrice = _newPrice;
    // }

    /// ----- EXTERNAL FUNCTIONS ----- ///
    ///@notice Activate all investitions of address
    ///@dev _stakingStartDate must be in past
    function activateInvestitions() external {
        require(
            _stakingStartDate < block.timestamp,
            "Activation is not enabled yet"
        );
        uint256 investNum = _investitionsOfUser[msg.sender];
        uint256 sum = 0;
        for (uint256 i = 0; i < investNum; i++) {
            InvestData memory inv = _investitions[msg.sender][i];
            if (!inv.withdrawn) {
                sum++;
                _totalInvestitions -= inv.amount;
                _investitions[msg.sender][i].withdrawn = true;
                if (inv.pool == POOL_SEED) {
                    require(
                        _seed_tokens - inv.amount >= 0,
                        "Cant claim more than cap"
                    );
                    uint256 stakingTokens = (60 * inv.amount) / 100;
                    uint256 vestingTokens = (30 * inv.amount) / 100;
                    _transfer(
                        address(this),
                        msg.sender,
                        inv.amount - vestingTokens - stakingTokens
                    );
                    _addVesting(
                        msg.sender,
                        20,
                        vestingTokens,
                        _stakingStartDate
                    );
                    _stake(
                        msg.sender,
                        stakingTokens,
                        12 * 30,
                        _stakingStartDate,
                        _initialTokenPrice
                    );
                    _seed_tokens -= inv.amount;
                    emit withdrawInvest(msg.sender, POOL_SEED, inv.amount);
                } else if (inv.pool == POOL_PRESALE) {
                    require(
                        _presale_tokens - inv.amount >= 0,
                        "Cant claim more than cap"
                    );
                    uint256 stakingTokens = (50 * inv.amount) / 100;
                    uint256 vestingTokens = (40 * inv.amount) / 100;
                    _transfer(
                        address(this),
                        msg.sender,
                        inv.amount - vestingTokens - stakingTokens
                    );
                    _addVesting(
                        msg.sender,
                        18,
                        vestingTokens,
                        _stakingStartDate
                    );
                    _stake(
                        msg.sender,
                        stakingTokens,
                        9 * 30,
                        _stakingStartDate,
                        _initialTokenPrice
                    );
                    _presale_tokens -= inv.amount;
                    emit withdrawInvest(msg.sender, POOL_PRESALE, inv.amount);
                } else if (inv.pool == POOL_TEAM) {
                    require(
                        _team_tokens - inv.amount >= 0,
                        "Cant claim more than cap"
                    );
                    uint256 stakingTokens = (60 * inv.amount) / 100;
                    uint256 vestingTokens = (30 * inv.amount) / 100;
                    _transfer(
                        address(this),
                        msg.sender,
                        inv.amount - vestingTokens - stakingTokens
                    );
                    _addVesting(
                        msg.sender,
                        20,
                        vestingTokens,
                        _stakingStartDate
                    );
                    _stake(
                        msg.sender,
                        stakingTokens,
                        12 * 30,
                        _stakingStartDate,
                        _initialTokenPrice
                    );
                    _team_tokens -= inv.amount;
                    emit withdrawInvest(msg.sender, POOL_TEAM, inv.amount);
                }
            }
        }
        require(sum > 0, "Nothing to activate");
    }

    ///@notice Activates Allocation using exteranl erc20 token
    ///@dev Requires .approve() to this contract address for spending external token
    function activateAllocation() external {
        require(
            _stakingStartDate < block.timestamp,
            "Activation is not enabled yet"
        );
        IERC20 token = IERC20(_allocationTokenAddress);
        uint256 balance = token.balanceOf(msg.sender);
        require(balance > 1000 ether, "No allocation founded");
        require(_presale2_tokens - balance >= 0, "Cant activate more than cap");
        token.transferFrom(msg.sender, address(this), balance);
        uint256 stakingTokens = (60 * balance) / 100;
        uint256 vestingTokens = (30 * balance) / 100;
        _transfer(address(this), msg.sender, balance - vestingTokens - stakingTokens);
        _addVesting(msg.sender, 12, vestingTokens, _stakingStartDate);
        _stake(
            msg.sender,
            stakingTokens,
            6 * 30,
            _stakingStartDate,
            _initialTokenPrice
        );
        _presale2_tokens -= balance;
        _totalInvestitions -= balance;
        emit withdrawInvest(msg.sender, POOL_PRESALE2, balance);
    }

    ///@notice Stakes tokens for duration(days)
    ///@param _amount Amount of tokens to stake
    ///@param _duration Stake duration in days
    function stake(uint256 _amount, uint256 _duration) external {
        require(msg.sender == tx.origin, "Smart Contracts calls not allowed");
        _transfer(msg.sender, address(this), _amount);
        _stake(
            msg.sender,
            _amount,
            _duration,
            block.timestamp,
            _getTokenPrice()
        );
    }

    ///@notice Unstakes tokens for selected slot
    ///@dev Can be wthdrawn only once
    ///@param _slot Slot to unstake
    function unstake(uint256 _slot) external {
        require(msg.sender == tx.origin, "Smart Contracts calls not allowed");
        Stake memory s = _stakes[msg.sender][_slot];
        require(s.endPrice == 0, "Cant be unstaked again");
        uint256 actPrice = _getTokenPrice();
        require(
            block.timestamp >= (s.startDate + s.duration * 1 days),
            "Staking end date not reached"
        );
        _stakes[msg.sender][_slot].endPrice = actPrice;
        (
            uint256 tokensToUser,
            uint256 tokensToXtra,
            bool tokensFromXtra
        ) = _calculateWithdraw(msg.sender, _slot, actPrice);
        if (tokensFromXtra) {
            require(_xtra_fund >= tokensToXtra, "Xtra fund is empty");
            _mint(msg.sender, tokensToXtra);
            _transfer(address(this), msg.sender, tokensToUser);
            _xtra_fund -= tokensToXtra;
            _totalStaked -= tokensToUser;
            emit Unstaked(
                msg.sender,
                _slot,
                true,
                actPrice,
                tokensToXtra + tokensToUser,
                tokensToXtra,
                block.timestamp,
                false
            );
        } else {
            uint256 sum = 0;
            if (tokensToUser > 0) {
                _transfer(address(this), msg.sender, tokensToUser);
                sum += tokensToUser;
            }
            if (tokensToXtra > 0) {
                _burn(address(this), tokensToXtra);
                sum += tokensToXtra;
                _xtra_fund += tokensToXtra;
            }
            emit Unstaked(
                msg.sender,
                _slot,
                false,
                actPrice,
                tokensToUser,
                tokensToXtra,
                block.timestamp,
                false
            );
            _totalStaked -= sum;
        }
    }

    ///@notice Liquidate stake position
    ///@param _slot Stake slot
    function liquidateStake(uint256 _slot) external {
        require(msg.sender == tx.origin, "Smart Contracts calls not allowed");
        require(
            _stakes[msg.sender][_slot].endPrice == 0,
            "Cant be unstaked again"
        );
        Stake memory s = _stakes[msg.sender][_slot];
        require(
            block.timestamp < (s.startDate + s.duration * 1 days),
            "Staking end date is reached"
        );
        uint256 actPrice = _getTokenPrice();
        (
            uint256 tokensToWithdraw,
            uint256 tokensToBurn
        ) = _calculateLiquidationReturn(msg.sender, _slot, actPrice);
        if (tokensToWithdraw > 0) {
            _transfer(address(this), msg.sender, tokensToWithdraw);
        }
        if (tokensToBurn > 0) {
            _burn(address(this), tokensToBurn);
            _xtra_fund += tokensToBurn / 2;
        }
        _stakes[msg.sender][_slot].endPrice = actPrice;
        _totalStaked -= s.amount;
        emit Unstaked(
            msg.sender,
            _slot,
            false,
            actPrice,
            tokensToWithdraw,
            tokensToBurn / 2,
            block.timestamp,
            true
        );
    }

    ///@notice Claims tokens from vesting slot
    ///@param _slot Vesting slot
    function claimVesting(uint256 _slot) external {
        require(
            block.timestamp < _vestingLastDate,
            "Cant be claimed - time is up"
        );
        Vesting memory v = _vestings[msg.sender][_slot];
        uint256 completedMonths = (block.timestamp - v.startDate) / 30 days;
        uint256 toWithdrawParts = completedMonths - v.withdrawnParts;
        uint256 canBeWithdrawn = v.duration - v.withdrawnParts;
        if (toWithdrawParts >= canBeWithdrawn) {
            toWithdrawParts = canBeWithdrawn;
        }
        require(toWithdrawParts > 0, "No parts to withdraw");
        uint256 tokensToMint = (v.amount * toWithdrawParts) / v.duration;
        _vestings[msg.sender][_slot].withdrawnParts =
            _vestings[msg.sender][_slot].withdrawnParts +
            toWithdrawParts;
        _transfer(address(this), msg.sender, tokensToMint);
        emit MintedFromVesting(msg.sender, _slot, tokensToMint);
        _totalVestings -= tokensToMint;
    }
}
