// script/deployBridgeWithLogging.ts
import { ethers } from "hardhat";
import * as dotenv from "dotenv";
import fs from "fs";
dotenv.config();

const {
  BVP_TOKEN_ADDRESS
} = process.env;

const USDC_SEPOLIA = "0x5425890298aed601595a70AB815c96711a31Bc65";
const INBOX_SEPOLIA = "0x6BEbC4925716945D46F0Ec336D5C2564F419682C";

async function main() {
  const [deployer] = await ethers.getSigners();
  console.log("Deployer:", deployer.address);

  const escrow = deployer.address;

  const L2Receiver = await ethers.getContractFactory("L2BVPReceiver");
  const l2Receiver = await L2Receiver.deploy(BVP_TOKEN_ADDRESS, escrow);
  await l2Receiver.deployed();
  console.log("L2BVPReceiver deployed at:", l2Receiver.address);

  const L1USDC = await ethers.getContractFactory("L1USDCGateway");
  const l1USDC = await L1USDC.deploy(USDC_SEPOLIA, INBOX_SEPOLIA, l2Receiver.address);
  await l1USDC.deployed();
  console.log("L1USDCGateway deployed at:", l1USDC.address);

  const L1ETH = await ethers.getContractFactory("L1ETHGateway");
  const l1ETH = await L1ETH.deploy(INBOX_SEPOLIA, l2Receiver.address);
  await l1ETH.deployed();
  console.log("L1ETHGateway deployed at:", l1ETH.address);

  const MockARB = await ethers.getContractFactory("MockARB");
  const mockARB = await MockARB.deploy();
  await mockARB.deployed();
  console.log("MockARB deployed at:", mockARB.address);

  const L1ARB = await ethers.getContractFactory("L1ARBGateway");
  const l1ARB = await L1ARB.deploy(mockARB.address, INBOX_SEPOLIA, l2Receiver.address);
  await l1ARB.deployed();
  console.log("L1ARBGateway deployed at:", l1ARB.address);

  // Save addresses to deployments.json
  const deployments = {
    deployer: deployer.address,
    l2Receiver: l2Receiver.address,
    l1USDCGateway: l1USDC.address,
    l1ETHGateway: l1ETH.address,
    mockARB: mockARB.address,
    l1ARBGateway: l1ARB.address
  };

  fs.writeFileSync("deployments.json", JSON.stringify(deployments, null, 2));
  console.log("✅ Deployment complete. Addresses saved to deployments.json");
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
