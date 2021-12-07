// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";

/// @title Xtra Staking Contract
/// @author bs
/// @notice Contract was not audited
contract XtraStaking is Ownable {
    /// ----- VARIABLES ----- ///
    uint256 internal _xtra_fund = 8e10 ether; //80 mlrd

    uint256 internal constant DAYS_LIMIT_1 = 729;
    uint256 internal constant DAYS_LIMIT_2 = 3649;
    uint256 internal constant DAYS_LIMIT_MAX = 6000;

    uint256 internal constant PERC_LIMIT_1 = 14;
    uint256 internal constant PERC_LIMIT_2 = 10;

    uint256 internal _totalStaked = 0;
    uint256 internal _stakingStartDate;

    struct Stake {
        uint256 startDate;
        uint256 duration;
        uint256 amount;
        uint256 startPrice;
        uint256 endPrice;
        uint256 roi;
        uint256 guarantee;
    }

    mapping(address => mapping(uint256 => Stake)) internal _stakes;
    mapping(address => uint256) internal _stakesOfUser;

    /// ----- EVENTS ----- ///
    event Staked(
        address indexed _staker,
        uint256 indexed _stakeNum,
        uint256 _duration,
        uint256 _amount,
        uint256 _startPrice,
        uint256 _roi,
        uint256 _startDate,
        uint256 _guarantee
    );

    event Unstaked(
        address indexed _staker,
        uint256 indexed _stakeNum,
        bool indexed _fromFund,
        uint256 _endPrice,
        uint256 _amountWithdrawed,
        uint256 _amountToXtra,
        uint256 _endDate,
        bool _isLiquidated
    );

    /// ----- CONSTRUCTOR ----- ///
    constructor() {}

    /// ----- VIEWS ----- ///
    ///@notice Returns sum of staked tokens of address
    ///@param _stakerAddress - address to check
    ///@return 0 sumStaked - sum of staked tokens
    function sumStakedByUser(address _stakerAddress)
        external
        view
        returns (uint256)
    {
        return (_sumStakedByUser(_stakerAddress));
    }

    ///@notice Returns stake params for requested staker address and stake slot
    ///@param _stakerAddress - staker address
    ///@param _slot - stake slot
    ///@return 0 startDate - stake Start Date
    ///@return 1 duration - stake duration in days
    ///@return 2 amount - stake amount in tokens
    ///@return 3 startPrice - the price of token when it was activated (staked)
    ///@return 4 endPrice - the price of token when it was unstaked
    ///@return 5 roi - expected roi of stake
    function getStake(address _stakerAddress, uint256 _slot)
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        Stake memory s = _stakes[_stakerAddress][_slot];
        return (
            s.startDate,
            s.duration,
            s.amount,
            s.startPrice,
            s.endPrice,
            s.roi,
            s.guarantee
        );
    }

    ///@notice Returns number of all stakes of address
    ///@param _stakerAddress - staker address
    ///@return 0 stakesNum - number of all stakes of address
    function userStakesNum(address _stakerAddress)
        external
        view
        returns (uint256)
    {
        return _stakesOfUser[_stakerAddress];
    }

    ///@notice Calculates expected roi for stake amount and duration
    ///@param _amount - stake amount
    ///@param _duration - stake duration
    ///@return 0 durationBonus - duration bonus
    ///@return 1 amountBonus - amount bonus
    ///@return 2 roi - roi
    function calculateRoi(uint256 _amount, uint256 _duration)
        external
        pure
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        if (_amount < 1 ether) return (0, 0, 0);
        else if (_duration < 1) return (0, 0, 0);
        else if (_duration > DAYS_LIMIT_MAX) return (0, 0, 0);
        else {
            (
                uint256 _durationBonus,
                uint256 _amountBonus,
                uint256 _roi
            ) = _calculateRoi(_amount, _duration);
            return (_durationBonus, _amountBonus, _roi);
        }
    }

    /// ----- INTERNAL METHODS ----- ///
    ///@notice Returns sum of staked tokens of address
    ///@param _stakerAddress - address to check
    ///@return 0 sumStaked - sum of staked tokens
    function _sumStakedByUser(address _stakerAddress)
        internal
        view
        returns (uint256)
    {
        uint256 sum = 0;
        for (uint256 i = 0; i < _stakesOfUser[_stakerAddress]; i++) {
            Stake memory s = _stakes[_stakerAddress][i];
            if (s.endPrice == 0) {
                sum += s.amount;
            }
        }
        return sum;
    }

    ///@notice Returns percent duration bonus
    ///@param _amount - address to check
    ///@return 0 amountBonus - amount bonus in percent * 10**11
    function _biggerAmountBonus(uint256 _amount)
        internal
        pure
        returns (uint256)
    {
        uint256 tmp = _amount / 16 / 10**14;
        if (tmp < 10**11) {
            return (uint256(tmp));
        } else return (uint256(10**11));
    }

    ///@notice Returns percent amount bonus
    ///@param _duration - address to check
    ///@return 0 durationBonus - amount bonus in percent * 10**11
    function _longerDurationBonus(uint256 _duration)
        internal
        pure
        returns (uint256)
    {
        if (_duration <= DAYS_LIMIT_1) {
            uint256 bonusPerc = ((_duration * 10**10) / 365) * PERC_LIMIT_1;
            return (bonusPerc);
        } else if (_duration <= DAYS_LIMIT_2) {
            uint256 stakeYears = (_duration * 1000000000) / 365;
            uint256 bonusPerc = (stakeYears * stakeYears * 338) /
                10000000000 +
                58 *
                stakeYears +
                97700000000;
            return (bonusPerc);
        } else if (_duration <= DAYS_LIMIT_MAX) {
            uint256 stakeYears = (_duration * 1000000000) / 365;
            uint256 bonusPerc = (766 * stakeYears - 3500000000000);
            return (bonusPerc);
        }
        return (0);
    }

    ///@notice Calculates expected roi for stake amount and duration
    ///@param _amount - stake amount
    ///@param _duration - stake duration
    ///@return 0 durationBonus - duration bonus
    ///@return 1 amountBonus - amount bonus
    ///@return 2 roi - roi
    function _calculateRoi(uint256 _amount, uint256 _duration)
        internal
        pure
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        uint256 _durationBonus = _longerDurationBonus(_duration);
        uint256 _amountBonus = _biggerAmountBonus(_amount);
        uint256 _roi = (_durationBonus +
            (_durationBonus * _amountBonus) /
            10**12);
        return (_durationBonus, _amountBonus, _roi);
    }

    ///@notice Calculates return for selected staking slot with actual token price. If isFromXtra is true xtraAmount will be minted from xtra fund to staker address. Else xtra amount will be burn and added to xtra fund.
    ///@param _stakerAddress - Address of staker
    ///@param _slot - Slot of stake
    ///@param _actualPrice - price for which return be calculated
    ///@return 0 userAmount - amount in xtra tokens returns to user
    ///@return 1 xtraAmount - amount in xtra tokens from/to xtra fund
    ///@return 2 isFromXtra - true if tokens need to be minted from xtra fund. false if tokens will burn and added to xtra fund
    function _calculateWithdraw(
        address _stakerAddress,
        uint256 _slot,
        uint256 _actualPrice
    )
        internal
        view
        returns (
            uint256,
            uint256,
            bool
        )
    {
        Stake memory s = _stakes[_stakerAddress][_slot];
        uint256 actualPrice = _actualPrice;
        uint256 startValue = (s.startPrice * s.amount) / 10**8;
        uint256 endValue = (actualPrice * s.amount) / 10**8;
        uint256 roi = (startValue * s.roi) / 10**12;
        if (endValue == startValue) {
            return (s.amount, 0, false);
        } else if (endValue > startValue) {
            uint256 grossProfit = endValue - startValue;
            if (grossProfit <= roi) {
                return (s.amount, 0, false);
            } else if (grossProfit > roi) {
                uint256 diff = grossProfit - roi;
                uint256 toWithdraw = 0;
                if (diff >= startValue * 2) {
                    toWithdraw = ((roi + startValue * 2) * 10**8) / actualPrice;
                } else {
                    toWithdraw =
                        ((roi + startValue + diff / 2) * 10**8) /
                        actualPrice;
                }
                uint256 tokensToXtra = s.amount - toWithdraw;
                return (toWithdraw, tokensToXtra, false);
            }
        } else {
            uint256 guarantedPrice = s.startPrice -
                ((s.startPrice * s.guarantee) / 100);
            uint256 tokensFromXtra;
            if (guarantedPrice <= _actualPrice) {
                //100000 <= 600000 true
                uint256 diff = startValue - endValue; //10 000 -
                tokensFromXtra = (diff * 10**8) / actualPrice;
            } else {
                tokensFromXtra =
                    ((s.amount * startValue) /
                        ((s.amount * guarantedPrice) / 10**8)) -
                    s.amount;
            }
            if (tokensFromXtra > _xtra_fund) {
                tokensFromXtra = _xtra_fund;
            }
            return (s.amount, tokensFromXtra, true);
        }
        return (0, 0, false);
    }

    ///@notice Calculates guarantee in percents
    ///@param _days - duration in days
    ///@return 0 guarantee - guarantee in percents
    function _calculateGuarantee(uint256 _days)
        internal
        pure
        returns (uint256)
    {
        if (_days <= 365) {
            return 50;
        } else if (_days <= 1095) {
            return 60;
        } else if (_days <= 1825) {
            return 70;
        } else if (_days <= 3650) {
            return 80;
        } else if (_days > 3650) {
            return 90;
        }
        return (0);
    }

    ///@notice Stakes tokens for duration(days)
    ///@param _address Staker address
    ///@param _amount Amount of tokens to stake
    ///@param _duration Stake duration in days
    ///@param _startDate Stake start date
    ///@param _tokenPrice Stake start token price
    function _stake(
        address _address,
        uint256 _amount,
        uint256 _duration,
        uint256 _startDate,
        uint256 _tokenPrice
    ) internal {
        require(_amount >= 1 ether, "Amount must be greather than 1");
        require(_duration >= 1, "Duration must be greather than 1");
        require(
            _duration <= DAYS_LIMIT_MAX,
            "Duration must be lower then max limit"
        );
        // _transfer(_address, address(this), _amount);
        (, , uint256 roi) = _calculateRoi(_amount, _duration);
        uint256 stakesNum = _stakesOfUser[_address];
        Stake memory newStake;
        newStake.startDate = _startDate;
        newStake.amount = _amount;
        newStake.duration = _duration;
        newStake.startPrice = _tokenPrice;
        newStake.roi = roi;
        newStake.guarantee = _calculateGuarantee(_duration);
        _stakes[_address][stakesNum] = newStake;
        emit Staked(
            _address,
            stakesNum,
            _duration,
            _amount,
            _tokenPrice,
            roi,
            _startDate,
            newStake.guarantee
        );
        _stakesOfUser[_address]++;
        _totalStaked += _amount;
    }

    ///@notice Calculates liquidation return from stake
    ///@param _address Staker address
    ///@param _slot Stake slot
    ///@param _actualPrice price for which liquidation return be calculated
    ///@return 0 tokensToWithdraw - tokens send back to user
    ///@return 1 tokensToBurn - tokens to burn
    function _calculateLiquidationReturn(
        address _address,
        uint256 _slot,
        uint256 _actualPrice
    ) internal view returns (uint256, uint256) {
        Stake memory s = _stakes[_address][_slot];
        uint256 endStakeTime = s.startDate + s.duration * 1 days;
        require(block.timestamp < endStakeTime, "Stake is ended");
        uint256 pastTime = block.timestamp - s.startDate;
        uint256 pastPerc = (pastTime * 10**5) / (endStakeTime - s.startDate);
        uint256 invValue = (s.startPrice * s.amount) / 10**8;
        uint256 retValue = (invValue * pastPerc) / 10**5;
        uint256 retAmount = (retValue * 10**8) / s.startPrice;
        if (_actualPrice < s.startPrice) {
            uint256 toBurn = s.amount - retAmount;
            return (retAmount, toBurn);
        } else {
            uint256 invValue2 = (_actualPrice * s.amount) / 10**8;
            uint256 retValue2 = (invValue2 * pastPerc) / 10**5;
            if (retValue2 > retValue) {
                uint256 retAmount2 = (retValue * 10**8) / _actualPrice;
                uint256 toBurn = s.amount - retAmount2;
                return (retAmount2, toBurn);
            } else {
                uint256 toBurn = s.amount - retAmount;
                return (retAmount, toBurn);
            }
        }
    }

    ///@notice Sets start staking date
    ///@param _newDate Start Staking Date
    function setStakingStartDate(uint256 _newDate) external onlyOwner {
        require(_stakingStartDate == 0, "Cant be set again");
        _stakingStartDate = _newDate;
    }
}
