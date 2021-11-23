// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract AlloactionXtraToken is ERC20 {
    constructor(string memory _name, string memory _ticker) ERC20(_name, _ticker) {
        _mint(msg.sender, 1500000000*(10**18));
    }
}
