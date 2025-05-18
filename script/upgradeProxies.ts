import { ethers, upgrades } from "hardhat";

async function upgradeProxy(proxyAddress: string, fullyQualifiedName: string) {
  const Contract = await ethers.getContractFactoryFromArtifact(
    await hre.artifacts.readArtifact(fullyQualifiedName)
  );
  const upgraded = await upgrades.upgradeProxy(proxyAddress, Contract);
  console.log(`✅ ${fullyQualifiedName} upgraded at proxy: ${upgraded.address}`);
}

async function main() {
  console.log("Upgrading proxies on Arbitrum Sepolia...");

  const stakingProxy = "0xb3dC17CbeAEdF65A8F2A2B5aEbF72738d20E130F";
  const gasRouterProxy = "0xB5d7De4442D92F2007C44eE88E06Ea5b33dd2dC9";

  // ✅ Use original logic (layout-safe)
  await upgradeProxy(stakingProxy, "contracts/BVPStakingUpgradeable.sol:BVPStakingUpgradeable");
  await upgradeProxy(gasRouterProxy, "contracts/GasRouterUpgradeable.sol:GasRouterUpgradeable");
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
