import { ethers } from "hardhat";

async function main() {
  const [deployer] = await ethers.getSigners();
  console.log("Deploying from:", deployer.address);

  // === Deploy BVPToken ===
  const Token = await ethers.getContractFactory("BVPToken");
  const token = await Token.deploy(deployer.address); // treasury = deployer
  await token.waitForDeployment();
  const tokenAddress = await token.getAddress();
  console.log("✅ BVPToken deployed at:", tokenAddress);

  // === Deploy BVPStaking ===
  const Staking = await ethers.getContractFactory("BVPStaking");
  const staking = await Staking.deploy(tokenAddress);
  await staking.waitForDeployment();
  const stakingAddress = await staking.getAddress();
  console.log("✅ BVPStaking deployed at:", stakingAddress);

  // === Deploy GasRouter (with diagnostic logic) ===
  const GasRouter = await ethers.getContractFactory("GasRouter");
  const router = await GasRouter.deploy(tokenAddress, deployer.address);
  await router.waitForDeployment();
  const routerAddress = await router.getAddress();
  console.log("✅ GasRouter deployed at:", routerAddress);

  // === Seed balances and approvals ===
  const approveAmount = ethers.parseEther("1000000");
  await token.approve(stakingAddress, approveAmount);
  await token.approve(routerAddress, approveAmount);
  await token.transfer(routerAddress, ethers.parseEther("3000"));
  await token.transfer(stakingAddress, ethers.parseEther("2000"));

  console.log("✅ Contracts funded and approved");
  console.log("📌 Addresses:");
  console.log("  BVPToken:   ", tokenAddress);
  console.log("  Staking:    ", stakingAddress);
  console.log("  GasRouter:  ", routerAddress);
}

main().catch((err) => {
  console.error(err);
  process.exitCode = 1;
});
