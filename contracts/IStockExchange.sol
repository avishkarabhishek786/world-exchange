// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.10;

interface IStockExchange {

    function getStockPrice(uint256 oraclePrice, bytes memory signature, uint256 nonce) external view returns (uint);

    function buy(address to, uint paymentAmount, uint256 oraclePrice, bytes memory signature, uint256 nonce) external;

    function sell(address from, uint sellAmount, uint256 oraclePrice, bytes memory signature, uint256 nonce) external;

}