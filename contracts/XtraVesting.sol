// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

/// @title Xtra Vesting Contract
/// @author bs
/// @notice Contract was not audited
contract XtraVesting {
    /// ----- VARIABLES ----- ///
    uint256 internal immutable _vestingLastDate;
    struct Vesting {
        uint256 startDate;
        uint256 duration;
        uint256 amount;
        uint256 withdrawnParts;
    }
    uint256 _totalVestings;
    mapping(address => mapping(uint256 => Vesting)) internal _vestings;
    mapping(address => uint256) internal _vestingsOfUser;

    /// ----- EVENTS ----- ///
    event AddedVesting(
        address indexed _participant,
        uint256 indexed _slot,
        uint256 _amount,
        uint256 _duration
    );
    event MintedFromVesting(
        address indexed _participant,
        uint256 indexed _slot,
        uint256 _amount
    );

    /// ----- CONSTRUCTOR ----- ///
    constructor() {
        _vestingLastDate = block.timestamp + 30 * 30 days;
    }

    /// ----- VIEWS ----- ///

    ///@notice Returns max date of minting from vesting
    function getVestingLastDate() external view returns (uint256) {
        return _vestingLastDate;
    }

    ///@notice Returns vesting info for slot
    ///@param _claimerAddress - claimer address
    ///@param _slot - vesting slot
    ///@return 0 startDate - staking start date
    ///@return 1 duration -  staking duration in months
    ///@return 2 amount - staking amount in tokens
    ///@return 3 withdrawnParts - staking withdrawn parts in months
    function getVesting(address _claimerAddress, uint256 _slot)
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        Vesting memory v = _vestings[_claimerAddress][_slot];
        return (v.startDate, v.duration, v.amount, v.withdrawnParts);
    }

    ///@notice Returns number of all vestings of address
    ///@param _claimerAddress - claimer address
    ///@return 0 vestingNum - number of all invests of address
    function userVestingNum(address _claimerAddress)
        external
        view
        returns (uint256)
    {
        return _vestingsOfUser[_claimerAddress];
    }

    /// ----- INTERNAL METHODS ----- ///

    ///@notice Adds vesting
    ///@param _address - vesting receiver address
    ///@param _duration - vesting duration
    ///@param _amount - vesting amount
    ///@param _startDate - vesting start date
    function _addVesting(
        address _address,
        uint256 _duration,
        uint256 _amount,
        uint256 _startDate
    ) internal {
        uint256 vestingNum = _vestingsOfUser[_address];
        Vesting memory newVesting;
        newVesting.startDate = _startDate;
        newVesting.amount = _amount;
        newVesting.duration = _duration;
        _vestings[_address][vestingNum] = newVesting;
        _vestingsOfUser[_address]++;
        _totalVestings += _amount;
        emit AddedVesting(_address, vestingNum, _amount, _duration);
    }
}
