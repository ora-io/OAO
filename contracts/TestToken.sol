// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";

contract TestToken is ERC20Permit, ERC20Burnable {

    uint256 private constant TOTAL_SUPPLY = 10000 * 10 ** 18; 

    constructor() ERC20Permit("TEST") ERC20("Test Token", "TEST") {
        _mint(msg.sender, TOTAL_SUPPLY);
    }
}