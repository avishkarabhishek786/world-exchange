//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.10;

import "./Stocks.sol";
 
contract StocksFactory {

    uint stocksCount;
    mapping(uint=>Stocks) public stocksList;

    function createStocks(string memory _name, string memory _symbol) external payable {
        // todo: check for already existing token symbol as well
        require(address(stocksList[stocksCount])==address(0), "Stock already exists.");
        Stocks newToken = new Stocks(_name, _symbol);
        stocksList[stocksCount] = newToken;
        stocksCount++;
    }

    function getStocksList() external view returns (Stocks[] memory) {
        Stocks[] memory sl = new Stocks[](stocksCount);
        for(uint i=0; i<stocksCount; i++) {
            sl[i] = stocksList[i];
        }
        return sl;
    }

}