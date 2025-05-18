import { ethers } from "hardhat";
import * as dotenv from "dotenv";
dotenv.config();

async function main() {
  const [deployer] = await ethers.getSigners();
  console.log("Deploying L2BVPTokenGateway with account:", deployer.address);

  const bvpToken   = process.env.BVP_TOKEN_ADDRESS!;       // same L2 token address
  const l1Gateway  = process.env.L1_BVP_GATEWAY_ADDRESS!;
  if (!bvpToken || !l1Gateway) {
    throw new Error("Set BVP_TOKEN_ADDRESS & L1_BVP_GATEWAY_ADDRESS in .env");
  }

  const Factory = await ethers.getContractFactory("L2BVPTokenGateway");
  const gateway = await Factory.deploy(bvpToken, l1Gateway);
  await gateway.deployed();

  console.log("✅ L2BVPTokenGateway:", gateway.address);
}

main()
  .then(() => process.exit(0))
  .catch(err => {
    console.error(err);
    process.exit(1);
  });
