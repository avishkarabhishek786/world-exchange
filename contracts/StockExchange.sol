//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "hardhat/console.sol";

interface IStocks is IERC20 {}
interface IStocksFactory {
    function getStocksData() external view returns (IStocks[] memory, bool[] memory);
    function isStockTrading(uint id) external view returns (bool);
}

contract StockExchange {

    IERC20 public immutable USDC;

    constructor(address _usdc) {
        USDC = IERC20(_usdc);
    }

    

}
