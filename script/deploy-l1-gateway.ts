import { ethers } from "hardhat";
import * as dotenv from "dotenv";
dotenv.config();

async function main() {
  const [deployer] = await ethers.getSigners();
  console.log("Deploying L1BVPTokenGateway with account:", deployer.address);

  const bvpToken       = process.env.BVP_TOKEN_ADDRESS!;
  const routerAddress  = process.env.L1_GATEWAY_ROUTER_ADDRESS!;
  if (!bvpToken || !routerAddress) {
    throw new Error("Set BVP_TOKEN_ADDRESS & L1_GATEWAY_ROUTER_ADDRESS in .env");
  }

  const Factory = await ethers.getContractFactory("L1BVPTokenGateway");
  const gateway = await Factory.deploy(bvpToken, routerAddress);
  await gateway.deployed();

  console.log("✅ L1BVPTokenGateway:", gateway.address);
}

main()
  .then(() => process.exit(0))
  .catch(err => {
    console.error(err);
    process.exit(1);
  });
