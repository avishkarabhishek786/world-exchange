// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;  

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "./IStocks.sol";
interface IStocksFactory {
    function getExchange(string memory _symbol) external view returns (address);
}
 
contract Stocks is ERC20, ERC20Burnable, IStocks {

    IStocksFactory immutable private Factory;
    address immutable private adminWallet;
    constructor(string memory _name, string memory _symbol, address _factory, address _adminWallet) ERC20(_name, _symbol) {
        Factory = IStocksFactory(_factory);
        adminWallet = _adminWallet;
    }

    function mint(address to, uint amount) external override returns (uint amountOut) {
        require(msg.sender==Factory.getExchange(symbol()), "mint fail");
        uint _fee = fees(amount);
        amountOut = amount - _fee;
        _mint(adminWallet, _fee);
        _mint(to, amountOut);
    }

    function burn(address to, uint amount) external override returns (uint amountOut)  {
        require(msg.sender==Factory.getExchange(symbol()), "burn fail");
        uint _fee = fees(amount);
        amountOut = amount - _fee;
        _mint(adminWallet, _fee);
        _burn(to, amount);
    }

    function fees(uint amount) private pure returns (uint) {
        return ( amount * 2 ) / 100;
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount)
        internal
        override
    {
        super._beforeTokenTransfer(from, to, amount);
    }

}