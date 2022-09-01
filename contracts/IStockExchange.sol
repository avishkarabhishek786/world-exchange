// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.10;

interface IStockExchange {
    function getStockPrice() external pure returns (uint);

    function buy(uint paymentAmount) external;

    function sell(uint sellAmount) external;
}