//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./IStockExchange.sol";
interface Istocks is IERC20 {
     function mint(address to, uint amount) external returns (uint amountOut);
     function burn(address to, uint amount) external returns (uint amountOut);
}
interface IstocksFactory {
     function getStocksData() external view returns (Istocks[] memory, bool[] memory);
     function isStockTrading(uint id) external view returns (bool);
}

contract StockExchange is ReentrancyGuard, IStockExchange {

    Istocks public stock;

    IERC20 public immutable usdc;

    constructor(address _stock, address _usdc) {
        usdc = IERC20(_usdc);
        stock = Istocks(_stock);
    }

    function getStockPrice() public pure override returns (uint) {
        return 100;
    }

    // Buy Stocks
    function buy(uint paymentAmount) external nonReentrant {
        usdc.transferFrom(msg.sender, address(this), paymentAmount);
        stock.mint(msg.sender, paymentAmount/getStockPrice());  
    }

    // Sell Stocks
    function sell(uint sellAmount) external nonReentrant {
        stock.burn(msg.sender, sellAmount);
        usdc.transfer(msg.sender, sellAmount * getStockPrice());  
    }

}
