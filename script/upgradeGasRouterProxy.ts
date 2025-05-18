// script/upgradeGasRouterProxy.ts
import { ethers, upgrades } from "hardhat";

async function main() {
  const proxyAddress = "0xB5d7De4442D92F2007C44eE88E06Ea5b33dd2dC9";
  console.log("Upgrading GasRouterUpgradeable proxy at:", proxyAddress);

  const GasRouter = await ethers.getContractFactory("contracts/GasRouterUpgradeable.sol:GasRouterUpgradeable");
  const upgraded = await upgrades.upgradeProxy(proxyAddress, GasRouter);

  console.log("✅ Upgrade complete. New logic at:", await upgrades.erc1967.getImplementationAddress(proxyAddress));
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
