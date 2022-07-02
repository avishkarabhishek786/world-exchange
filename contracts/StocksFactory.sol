//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./Stocks.sol";
 
contract StocksFactory is Ownable {

    uint public stocksCount;

    struct StockData {
        Stocks stocks;
        bool allowTrade;
    }
    mapping(uint=>StockData) public stocksList;

    function createStocks(string memory _name, string memory _symbol) external payable onlyOwner {
        // check for already existing token symbol as well
        require(address(stocksList[stocksCount].stocks)==address(0), "Stock already exists.");
        Stocks newToken = new Stocks(_name, _symbol);
        stocksList[stocksCount] = StockData(newToken, true);
        stocksCount++;
    }

    function getStocksData() external view returns (Stocks[] memory, bool[] memory) {
        Stocks[] memory sl = new Stocks[](stocksCount);
        bool[] memory isTradableLis = new bool[](stocksCount);

        for(uint i=0; i<stocksCount; i++) {
            sl[i] = stocksList[i].stocks;
            isTradableLis[i] = stocksList[i].allowTrade;
        }
        return (sl, isTradableLis);
    }

    // Check if Stock exists and trading
    function isStockTrading(uint id) public view returns (bool) {
        return stocksList[id].allowTrade;
    }

    // Create function to disable a stock from trading
    function disableStock(uint id) external onlyOwner {
        stocksList[id].allowTrade = false;
    }
    

}