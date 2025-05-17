import { ethers } from "hardhat";
import * as dotenv from "dotenv";
dotenv.config({ path: "./.env" });

async function main() {
  const [deployer] = await ethers.getSigners();
  console.log("⛏️  Deploying on Orbit-Sepolia as:", deployer.address);

  // -- 1) BVPToken (attach or deploy)
  const tokenAddr = process.env.BVP_TOKEN_ADDRESS!;
  const token = await ethers.getContractAt("BVPToken", tokenAddr);
  console.log(`🔗 Attached BVPToken @ ${token.address}`);

  // -- 2) BVPStaking (attach or deploy)
  const stakeAddr = process.env.BVP_STAKING_ADDRESS!;
  const staking = await ethers.getContractAt("BVPStaking", stakeAddr);
  console.log(`🔗 Attached BVPStaking @ ${staking.address}`);

  // -- 3) GasRouter (fresh deploy unless you set GAS_ROUTER_ADDRESS in .env)
  const routerAddr = process.env.GAS_ROUTER_ADDRESS;
  let gasRouter;
  if (routerAddr) {
    gasRouter = await ethers.getContractAt("GasRouter", routerAddr);
    console.log(`🔗 Attached GasRouter @ ${gasRouter.address}`);
  } else {
    const Router = await ethers.getContractFactory("GasRouter");
    gasRouter = await Router.deploy(token.address, staking.address);
    await gasRouter.deployed();
    console.log(`🚀 Deployed GasRouter @ ${gasRouter.address}`);
  }

  console.log("✅ All done on Orbit-Sepolia subchain!");
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
