import { ethers } from "hardhat";

async function main() {
  const [deployer] = await ethers.getSigners();
  console.log("Deploying contracts with:", deployer.address);

  const Token = await ethers.getContractFactory("BVPToken");
  const token = await Token.deploy();
  await token.waitForDeployment();
  console.log("BVPToken deployed at:", await token.getAddress());

  const Staking = await ethers.getContractFactory("BVPStaking");
  const staking = await Staking.deploy(await token.getAddress());
  await staking.waitForDeployment();
  console.log("BVPStaking deployed at:", await staking.getAddress());
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
