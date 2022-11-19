//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "./IStockExchange.sol";
import "./VerifySigner.sol";

//import "hardhat/console.sol";
interface Istocks is IERC20 {
     function symbol() external view returns(string memory);
     function decimals() external view returns (uint8);
     function mint(address to, uint amount) external returns (uint amountOut);
     function burn(address to, uint amount) external returns (uint amountOut);
}
contract StockExchange is ReentrancyGuard, IStockExchange {

    using ECDSA for bytes32;

    //VerifySigner private vs;
 
    address payable public adminWallet;

    Istocks public stock;

    IERC20 public immutable usdc;

    // The address that signs each stock oracle price offline
    address immutable private oracleAdmin; 

    modifier verifyOracleSigner(uint256 oraclePrice, bytes memory signature, uint256 nonce) {
         require(VerifySigner.verify(oracleAdmin, stock.symbol(), oraclePrice, signature, nonce), "Caller is not signer.");
         _;
    }

    mapping(address => uint256) public buyNonces;
    mapping(address => uint256) public sellNonces;
    
    struct SellOrderTicket {
        uint id;
        uint usdToReceive;
        address seller;
        bool isUsdReceived;
    }

    mapping(uint => SellOrderTicket) public sellOrderTickets;

    enum TradeType {
        BUY,
        SELL
    }

    constructor(address _stock, address _usdc, address _oracleAdmin, address payable _adminWallet) {
        usdc = IERC20(_usdc);
        stock = Istocks(_stock);
        oracleAdmin = _oracleAdmin;
        adminWallet = _adminWallet;
    }

    function getMessageHash(string memory symbol, uint oraclePrice, uint nonce) external pure returns (bytes32) {
        return VerifySigner.getMessageHash(symbol, oraclePrice, nonce);
    }    
    
    function getEthSignedMessageHash(bytes32 msgHash) external pure returns (bytes32) {
        return VerifySigner.getEthSignedMessageHash(msgHash);
    }

    function recoverSigner(bytes32 _ethSignedMessageHash, bytes memory _signature) public pure returns(address) {
        return VerifySigner.recoverSigner(_ethSignedMessageHash, _signature);
    }
 
    function getStockPrice(uint256 oraclePrice, bytes memory signature, uint256 nonce) 
    public 
    view 
    verifyOracleSigner(oraclePrice, signature, nonce)
    override 
    returns (uint) {
        return oraclePrice; 
    }

    function getNonce(TradeType _type, address _addr) public view returns (uint256 nonce) {
        if(_type==TradeType.BUY) {
            nonce = buyNonces[_addr];
        } else if(_type==TradeType.SELL) {
            nonce = sellNonces[_addr];
        }
        return nonce;
    }

    function expectedBuyOutput(uint paymentAmount, uint256 oraclePrice) view public returns (uint) {
        return (paymentAmount*10**stock.decimals())/oraclePrice;
    }

    /**
     * @notice Buy new stocks based on the paymentAmount i.e stablecoins sent and oracle price
     * @param to address to send stocks to.
     * @param paymentAmount stablecoins being sent.
     * @param oraclePrice price returned by the oracle.
     * @param signature signature returned by the oracle.
     * @param nonce nonce returned by the oracle.
     */
    function buy(address to, uint paymentAmount, uint256 oraclePrice, bytes memory signature, uint256 nonce) 
    external 
    nonReentrant 
    {
        require(paymentAmount>=1 ** stock.decimals(), "Invalid paymentAmount"); 
        require(buyNonces[msg.sender]==nonce, "Invalid buy nonce");
        buyNonces[msg.sender]++;
        usdc.transferFrom(msg.sender, adminWallet, paymentAmount);
        uint price = getStockPrice(oraclePrice,signature, nonce);
        uint output = expectedBuyOutput(paymentAmount, price);
        stock.mint(to, output);  
    }

    /**
     * @notice Sell stocks based on the sellAmount sent and oracle price
     * @param from address to sell stocks from.
     * @param sellAmount amount of stocks being sold.
     * @param oraclePrice price returned by the oracle.
     * @param signature signature returned by the oracle.
     * @param nonce nonce returned by the oracle.
     */
    function sell(address from, uint sellAmount, uint256 oraclePrice, bytes memory signature, uint256 nonce) 
    external 
    nonReentrant 
    verifyOracleSigner(oraclePrice, signature, nonce)
    {
        require(sellAmount>=1 ** stock.decimals(), "Invalid sellAmount");
        require(sellNonces[msg.sender]==nonce, "Invalid sell nonce");
        
        stock.burn(from, sellAmount);
        
        // We cannot send USD from here because there can be shortage of it.
        // So a ticket is generated and user can get his USD from this ticket.
        // Applies only for sell orders 
        
        sellOrderTickets[nonce] = SellOrderTicket(
            nonce,
            sellAmount * getStockPrice(oraclePrice,signature, nonce),
            msg.sender,
            false
        );
        sellNonces[msg.sender]++;
    }

}
