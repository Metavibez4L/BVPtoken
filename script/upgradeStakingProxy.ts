// script/upgradeStakingProxy.ts
import { ethers, upgrades } from "hardhat";

async function main() {
  const proxyAddress = "0xb3dC17CbeAEdF65A8F2A2B5aEbF72738d20E130F";
  console.log("Upgrading BVPStakingUpgradeable proxy at:", proxyAddress);

  const Staking = await ethers.getContractFactory("contracts/BVPStakingUpgradeable.sol:BVPStakingUpgradeable");
  const upgraded = await upgrades.upgradeProxy(proxyAddress, Staking);

  console.log("✅ Upgrade complete. New logic at:", await upgrades.erc1967.getImplementationAddress(proxyAddress));
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
