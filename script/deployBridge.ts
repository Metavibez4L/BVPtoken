import { ethers } from "hardhat";
import * as dotenv from "dotenv";
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

  const L2Receiver = await ethers.deployContract("L2BVPReceiver", [
    BVP_TOKEN_ADDRESS,
    escrow
  ]);
  console.log("L2BVPReceiver deployed at:", L2Receiver.address);

  const l2Target = L2Receiver.address;

  const L1USDC = await ethers.deployContract("L1USDCGateway", [
    USDC_SEPOLIA,
    INBOX_SEPOLIA,
    l2Target
  ]);
  console.log("L1USDCGateway deployed at:", L1USDC.address);

  const L1ETH = await ethers.deployContract("L1ETHGateway", [
    INBOX_SEPOLIA,
    l2Target
  ]);
  console.log("L1ETHGateway deployed at:", L1ETH.address);

  const MockARB = await ethers.deployContract("MockARB");
  console.log("MockARB deployed at:", MockARB.address);

  const L1ARB = await ethers.deployContract("L1ARBGateway", [
    MockARB.address,
    INBOX_SEPOLIA,
    l2Target
  ]);
  console.log("L1ARBGateway deployed at:", L1ARB.address);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
