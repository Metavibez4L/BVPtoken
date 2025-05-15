import { ethers } from "hardhat";

async function main() {
  const [deployer] = await ethers.getSigners();
  console.log("Deploying from:", deployer.address);

  // ✅ Deploy BVPToken
  const Token = await ethers.getContractFactory("BVPToken");
  const token = await Token.deploy(deployer.address); // treasury = deployer
  await token.waitForDeployment();
  const tokenAddress = await token.getAddress();
  console.log("✅ BVPToken deployed at:", tokenAddress);

  // ✅ Deploy BVPStaking
  const Staking = await ethers.getContractFactory("BVPStaking");
  const staking = await Staking.deploy(tokenAddress);
  await staking.waitForDeployment();
  const stakingAddress = await staking.getAddress();
  console.log("✅ BVPStaking deployed at:", stakingAddress);

  // ✅ Deploy GasRouter
  const GasRouter = await ethers.getContractFactory("GasRouter");
  const router = await GasRouter.deploy(tokenAddress, deployer.address); // treasury = deployer
  await router.waitForDeployment();
  const routerAddress = await router.getAddress();
  console.log("✅ GasRouter deployed at:", routerAddress);

  // ✅ Approve GasRouter and Staking (optional: pre-approve them to handle tokens)
  const approveAmount = ethers.parseEther("1000000");
  await token.approve(stakingAddress, approveAmount);
  await token.approve(routerAddress, approveAmount);
  console.log("✅ Approved staking + router for token transfers");
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
