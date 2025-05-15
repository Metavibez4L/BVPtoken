import { ethers } from "hardhat";

async function main() {
  const [deployer] = await ethers.getSigners();
  console.log("Deploying from:", deployer.address);

  // Deploy BVPToken — the treasury arg is unused in logic but retained for compatibility
  const Token = await ethers.getContractFactory("BVPToken");
  const token = await Token.deploy(deployer.address);
  await token.waitForDeployment();
  const tokenAddress = await token.getAddress();
  console.log("BVPToken deployed at:", tokenAddress);

  // Deploy Staking
  const Staking = await ethers.getContractFactory("BVPStaking");
  const staking = await Staking.deploy(tokenAddress);
  await staking.waitForDeployment();
  const stakingAddress = await staking.getAddress();
  console.log("BVPStaking deployed at:", stakingAddress);

  // Optional: Initial transfer to staking treasury or tier vaults
  // await token.transfer(stakingAddress, ethers.parseEther("1000000"));

  console.log("\n✅ Deployment complete.");
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
