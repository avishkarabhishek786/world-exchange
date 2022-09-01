// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10; 

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract Wallets is ReentrancyGuard {

    address[] public acceptedTokens;
    mapping(address => uint) public usdBalances;

    event TopUpSuccess(address payee, uint amount);
    event WithdrawSuccess(address withdrawer, uint amount);

    constructor(address[] memory _acceptedTokens) {
        for(uint8 i; i<_acceptedTokens.length; i++) {
            acceptedTokens.push(_acceptedTokens[i]);
        }
    }

    function topUp(uint8 tokenId, uint amount) external nonReentrant {
        require(tokenId < acceptedTokens.length, "Invalid token");
        IERC20 paymentToken = IERC20(acceptedTokens[tokenId]);
        bool success = paymentToken.transferFrom(msg.sender, address(this), amount);
        require(success, "Top-up failed");
        usdBalances[msg.sender] += amount;
        emit TopUpSuccess(msg.sender, amount);
    }

    function withdraw(uint8 tokenId, uint amount) external nonReentrant {
        require(tokenId < acceptedTokens.length, "Invalid token");
        IERC20 paymentToken = IERC20(acceptedTokens[tokenId]);
        bool success = paymentToken.transfer(msg.sender, amount);
        require(success, "Withdraw failed");
        usdBalances[msg.sender] -= amount;
        emit WithdrawSuccess(msg.sender, amount);
    }

}