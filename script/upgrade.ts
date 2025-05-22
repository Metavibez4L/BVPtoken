import { ethers, upgrades } from "hardhat";
import * as dotenv from "dotenv";
dotenv.config();

async function main() {
  // Addresses from your .env
  const stakingProxy = process.env.BVP_STAKING_ADDRESS!;
  const gasRouterProxy = process.env.GAS_ROUTER_ADDRESS!;

  console.log("🔄 Upgrading BVPStakingUpgradeable at", stakingProxy);
  const Staking = await ethers.getContractFactory(
    "contracts/BVPStakingUpgradeable.sol:BVPStakingUpgradeable"
  );
  await upgrades.upgradeProxy(stakingProxy, Staking, { kind: "uups" });
  console.log("✅ BVPStakingUpgradeable upgraded");

  console.log("🔄 Upgrading GasRouterUpgradeable at", gasRouterProxy);
  const GasRouter = await ethers.getContractFactory(
    "contracts/GasRouterUpgradeable.sol:GasRouterUpgradeable"
  );
  await upgrades.upgradeProxy(gasRouterProxy, GasRouter, { kind: "uups" });
  console.log("✅ GasRouterUpgradeable upgraded");
}

main().catch(console.error);
