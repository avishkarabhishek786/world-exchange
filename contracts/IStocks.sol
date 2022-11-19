// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/interfaces/IERC20.sol";

interface IStocks is IERC20 {
    
    /**
     * @notice Mint new Stocks, sending it to the given address.  The amount of stablecoins
     * is passed in as amount.
     * @param to address to send the Stocks to.
     * @param amount Stablecoins sent for a successful mint.
     */
    function mint(address to, uint amount) external returns (uint amountOut);

    /**
     * @dev Burn Stocks in exchange for Stablecoins.
     * @param to address to send the Stablecoins to.
     * @param amount Amount of Stocks to burn.
     */
    function burn(address to, uint amount) external returns (uint amountOut);

}    