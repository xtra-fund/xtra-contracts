// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract ERC20SimpleToken is ERC20 {
    constructor(string memory _name, string memory _ticker) ERC20(_name, _ticker) {
        _mint(msg.sender, 10000000000000000000000000);
    }

    function mintMore(address _address, uint256 _amount) external{
        _mint(_address, _amount);
    }
}
