//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "hardhat/console.sol";

contract StockExchange {

    IERC20 public USDC;

    constructor(address _usdc) {
        USDC = IERC20(_usdc);
    }

    

}
