// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.10;

interface IStockExchange {

    function getStockPrice(uint256 oraclePrice, bytes memory signature, uint256 nonce) external view returns (uint);

    function buy(uint paymentAmount, uint256 oraclePrice, bytes memory signature, uint256 nonce) external;

    function sell(uint sellAmount, uint256 oraclePrice, bytes memory signature, uint256 nonce) external;

}