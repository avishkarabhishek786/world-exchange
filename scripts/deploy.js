// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `npx hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
const hre = require("hardhat");

async function main() {

  const [deployer] = await ethers.getSigners();

  // We get the contract to deploy
//   const VerifySigner = await hre.ethers.getContractFactory("VerifySigner");
//   const verifySigner = await VerifySigner.deploy();
//   await verifySigner.deployed();

  const AdminWallet = await hre.ethers.getContractFactory("AdminWallet");
  const StocksFactory = await hre.ethers.getContractFactory(
    "StocksFactory"
  );

  const Tether = await hre.ethers.getContractFactory("Tether");
  
  const adminWallet = await AdminWallet.deploy();
  await adminWallet.deployed();

  const stocksFactory = await StocksFactory.deploy(adminWallet.address, {from:deployer});
  await stocksFactory.deployed();

  const tether = await Tether.deploy();
  await tether.deployed();
  
  console.log("adminWallet deployed to:", adminWallet.address);
  console.log("stocksFactory deployed to:", stocksFactory.address);
  //console.log("verifySigner deployed to:", verifySigner.address);
  console.log("tether deployed to:", tether.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
