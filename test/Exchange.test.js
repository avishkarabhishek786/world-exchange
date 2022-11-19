const { expect, assert } = require("chai");
const { ethers, artifacts } = require("hardhat");
const { BN, expectRevert, constants } = require('@openzeppelin/test-helpers');
const { Contract } = require("ethers");

const Web3 = require('web3');
const web3 = new Web3(Web3.givenProvider || "ws://localhost:8545");

require('chai').use(require('chai-as-promised')).should()

const StocksFactory = artifacts.require('StocksFactory')
//const VerifySigner = artifacts.require('VerifySigner')
const Stocks = artifacts.require('Stocks')
const StockExchange = artifacts.require('StockExchange')
const AdminWallet = artifacts.require('AdminWallet')
const Tether = artifacts.require('Tether')

contract('StockExchange', (accounts) => {
    
    const [deployer, buyer1, buyer2, seller1, seller2] = accounts;

    let StocksFactoryContract, GoogStocksContract, GoogStockExchangeContract, 
    AdminWalletContract, TetherContract, VerifySignerContract, googStock, applStock, googAddr, 
    googExchangeAddr, tetherBalanceBuyer1, tetherBalanceBuyer2, tetherBalanceSeller1,
    tetherBalanceSeller2, oracleWallet;

    const DECIMALS = 10 ** 6;

    //const OracleRandWallet = ethers.Wallet.createRandom();
    //const OraclePrivateKey = OracleRandWallet.privateKey
    const OraclePrivateKey = "0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80"
    
    function bn(x) {
        return new BN(BigInt(Math.round(parseFloat(x))))
    }

    function toWei(amount) {
        return String(ethers.utils.parseEther(String(amount)))
    }

    function toDecimal6(amount) {
        return String(ethers.utils.parseUnits(String(amount), 6))
    }

    function shouldEqualApprox(x, y, acceptable_diff=1) {
        const diff = x.sub(y).abs(); 
        const diffPct = (diff.mul(bn(100))).div(x);
        acceptable_diff = bn(acceptable_diff);
        diffPct.should.be.bignumber.lte(acceptable_diff)
     }

    before(async()=>{
        AdminWalletContract = await AdminWallet.new({from:deployer})
        StocksFactoryContract = await StocksFactory.new( AdminWalletContract.address, {from:deployer})
        //VerifySignerContract = await VerifySigner.new( {from:deployer})
        TetherContract = await Tether.new( {from:deployer})

        oracleWallet = new ethers.Wallet(OraclePrivateKey);

    })

    describe('testing exchange functionality', ()=>{

        it('buyer1 and buyer2 have tether balance', async () => {
            await TetherContract.mint(buyer1, toDecimal6(2000), {from:buyer1})
            await TetherContract.mint(buyer2, toDecimal6(2000), {from:buyer2})

            tetherBalanceBuyer1 = String(await TetherContract.balanceOf(buyer1))
            tetherBalanceBuyer2 = String(await TetherContract.balanceOf(buyer2))

            tetherBalanceBuyer1.should.be.bignumber.eq(bn("2000000000"))
            tetherBalanceBuyer2.should.be.bignumber.eq(bn("2000000000"))

        })

        it('creates new stocks (GOOG, APPL) and their exchanges', async () => {
            
            googStock = await StocksFactoryContract.createStocks("Google Stocks", "GOOG", TetherContract.address)
            applStock = await StocksFactoryContract.createStocks("Apple Stocks", "APPL", TetherContract.address) 

            expect(googStock.tx.length).to.equal(66)

            const googlogs = googStock['logs'][0]['args'];

            //console.log(googlogs);

            googAddr = googlogs['stock']
            googExchangeAddr = googlogs['exchange']

            expect(await ethers.utils.isAddress(googAddr), true, "Not valid googAddr")
            expect(await ethers.utils.isAddress(googExchangeAddr), true, "Not valid googExchangeAddr")

            GoogStocksContract = await Stocks.at(googAddr)
            GoogStockExchangeContract = await StockExchange.at(googExchangeAddr)

        })  

        describe('testing trade functions', () => {

            let stockPrice, sig, nonce;

            it('gets correct stock price', async () => {

                const accounts = await ethers.getSigners(1)
    
                let signer = accounts[0];
    
                //console.log("signer.address", signer.address);
    
                const stockSymbol = await GoogStocksContract.symbol();
    
                expect(stockSymbol, "GOOG", "Symbol not same");
    
                let fetchRes = await fetch("https://api.khubero.com/marketprice");
                    
                let price = await fetchRes.json()
    
                price = price.filter(f=>f.symbol==stockSymbol).map(m=>m.price)[0];
    
                expect(price).to.be.a('number');

                price = price * DECIMALS;

                nonce = await GoogStockExchangeContract.getNonce(0, buyer1);
                    
                const hash = await GoogStockExchangeContract.getMessageHash(stockSymbol, price, nonce)
                sig = await signer.signMessage(ethers.utils.arrayify(hash))
    
                const ethHash = await GoogStockExchangeContract.getEthSignedMessageHash(hash)
    
                //console.log("signer          ", signer.address)
                //console.log("recoverVerifySignered signer", await GoogStockExchangeContract.recoverSigner(ethHash, sig))
    
                stockPrice = await GoogStockExchangeContract.getStockPrice(price,sig,0)  
                stockPrice.should.be.bignumber.eq(bn(price))

                console.log("stockPrice", String(stockPrice));
                
            })
    
            it('buys GOOG stocks worth 100 Stablecoins', async () => {

                const paymentAmount = 1000 * DECIMALS;

                const stockBalanceBefore = await GoogStocksContract.balanceOf(buyer1);

                const expectedStockOutput = bn((paymentAmount * DECIMALS) / stockPrice);
                const expectedFees = await GoogStocksContract.fees(bn(expectedStockOutput));

                const AdminWalletStockBalanceBefore = await GoogStocksContract.balanceOf(AdminWalletContract.address);
                
                // Allow googExchangeContract to spend buyer1 stablecoins
                await TetherContract.approve(googExchangeAddr, paymentAmount, {from:buyer1})

                await GoogStockExchangeContract.buy(buyer1, paymentAmount, stockPrice, sig, nonce, {from:buyer1});

                const stockBalanceAfter = await GoogStocksContract.balanceOf(buyer1);

                const AdminWalletStockBalanceAfter = await GoogStocksContract.balanceOf(AdminWalletContract.address);

                AdminWalletStockBalanceAfter.should.be.bignumber.eq(bn(AdminWalletStockBalanceBefore).add(expectedFees));
                shouldEqualApprox(bn(expectedStockOutput), bn(stockBalanceAfter).add(expectedFees));
                shouldEqualApprox(bn(stockBalanceBefore).add(expectedStockOutput.sub(expectedFees)), bn(stockBalanceAfter));

                // Tether Balance Buyer1
                tetherBalanceBuyer1After = await TetherContract.balanceOf(buyer1);
                tetherBalanceBuyer1After.should.be.bignumber.eq(bn(tetherBalanceBuyer1).sub(bn(paymentAmount)));
    
            })

            it('sells GOOG stocks', async() => {

                const sellAmount = 1 * DECIMALS;

                const stockBalanceBefore = await GoogStocksContract.balanceOf(buyer1);

                //console.log("stockBalanceBefore", String(stockBalanceBefore));

                const expectedCashOutput = sellAmount * stockPrice;

                tetherBalanceBuyer1Before = String(await TetherContract.balanceOf(buyer1))

                await GoogStockExchangeContract.sell(buyer1, sellAmount, stockPrice, sig, nonce, {from:buyer1});

                const stockBalanceAfter = await GoogStocksContract.balanceOf(buyer1);

                tetherBalanceBuyer1After = String(await TetherContract.balanceOf(buyer1))

                console.log("stockBalanceBefore", String(stockBalanceBefore));
                console.log("stockBalanceAfter", String(stockBalanceAfter));
                console.log("expectedCashOutput", String(expectedCashOutput));
                console.log("tetherBalanceBuyer1Before", String(tetherBalanceBuyer1Before));
                console.log("tetherBalanceBuyer1After", String(tetherBalanceBuyer1After));


            })

        })

        


    })

})


