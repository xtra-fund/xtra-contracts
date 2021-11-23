// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

/// @title Xtra Invest Contract
/// @author bs
/// @notice Contract was not audited
contract XtraInvesting {
    /// ----- VARIABLES ----- ///
    struct InvestData {
        uint256 amount;
        uint256 pool;
        bool withdrawn;
    }
    uint256 internal _totalInvestitions = 1500000000 ether; //initial value = max allocation tokens 
    mapping(address => mapping(uint256 => InvestData)) internal _investitions;
    mapping(address => uint256) internal _investitionsOfUser;

    /// ----- EVENTS ----- ///
    event withdrawInvest(
        address indexed _investor,
        uint256 indexed _pool,
        uint256 _amount
    );

    /// ----- CONSTRUCTOR ----- ///
    constructor() {}

    /// ----- VIEWS ----- ///
    ///@notice Returns number of all invests of address
    ///@param _investorAddress - staker address
    ///@return 0 investsNum - number of all invests of address
    function getInvestNum(address _investorAddress)
        external
        view
        returns (uint256)
    {
        return _investitionsOfUser[_investorAddress];
    }

    ///@notice Returns invest params for requested investor address and invest slot
    ///@param _investorAddress - investor address
    ///@param _slot - invest slot
    ///@return 0 amount - invest amount in tokens
    ///@return 1 pool - invest pool (see POOL_SEED, POOL_PRESALE, ...)
    ///@return 2 withdrawn - true if invest activated
    function getInvestitionInfo(address _investorAddress, uint256 _slot)
        external
        view
        returns (
            uint256,
            uint256,
            bool
        )
    {
        InvestData memory i = _investitions[_investorAddress][_slot];
        return (i.amount, i.pool, i.withdrawn);
    }

    /// ----- INTERNAL METHODS ----- ///
    ///@notice Adding investors to smart contract. Executable by contract owner only.
    ///@dev Contract owner only. _stakingStartDate must be initialized first.
    ///@param _addresses - Array of investors addresses
    ///@param _amounts - Array of amount to add
    ///@param _pools - Array of invest pools (POOL_SEED, POOL_PRESALE etc)
    function _addInvestors(
        address[] memory _addresses,
        uint256[] memory _amounts,
        uint256[] memory _pools
    ) internal {
        uint256 len = _addresses.length;
        require(
            len == _amounts.length && len == _pools.length,
            "Arrays lengths mismatch"
        );
        uint256 sum = 0;
        for (uint256 i = 0; i < len; i++) {
            address actAddress = _addresses[i];
            uint256 actAmount = _amounts[i];
            uint256 actPool = _pools[i];
            uint256 investNum = _investitionsOfUser[actAddress];
            InvestData memory newInvestition;
            newInvestition.amount = actAmount;
            newInvestition.pool = actPool;
            _investitions[actAddress][investNum] = newInvestition;
            _investitionsOfUser[actAddress]++;
            sum += actAmount;
        }
        require(
            _totalInvestitions + sum <= 6500000000 ether,
            "Max invest reached"
        );
        _totalInvestitions += sum;
    }
}
