import { ethers, upgrades } from "hardhat";

async function main() {
  const [deployer] = await ethers.getSigners();
  console.log("Deploying contracts with:", deployer.address);

  // Deploy BVPToken (non-upgradeable)
  const BVPToken = await ethers.getContractFactory("BVPToken");
  const token = await BVPToken.deploy(deployer.address);
  await token.waitForDeployment();
  console.log("BVPToken deployed to:", await token.getAddress());

  // Deploy BVPStakingUpgradeable via UUPS proxy
  const BVPStaking = await ethers.getContractFactory("BVPStakingUpgradeable");
  const staking = await upgrades.deployProxy(BVPStaking, [await token.getAddress()], {
    initializer: "initialize",
    kind: "uups",
  });
  await staking.waitForDeployment();
  console.log("BVPStakingUpgradeable proxy deployed to:", await staking.getAddress());

  // Deploy GasRouterUpgradeable via UUPS proxy
  const GasRouter = await ethers.getContractFactory("GasRouterUpgradeable");
  const gasRouter = await upgrades.deployProxy(GasRouter, [await token.getAddress(), deployer.address], {
    initializer: "initialize",
    kind: "uups",
  });
  await gasRouter.waitForDeployment();
  console.log("GasRouterUpgradeable proxy deployed to:", await gasRouter.getAddress());
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
