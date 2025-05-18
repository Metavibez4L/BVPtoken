import hre from "hardhat";
const { ethers, run } = hre;
import { CONTRACTS } from "./config";

async function getImplementation(proxyAddress: string): Promise<string> {
  const implSlot = "0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc";
  const implStorage = await hre.network.provider.send("eth_getStorageAt", [
    proxyAddress,
    implSlot,
    "latest"
  ]);
  return `0x${implStorage.slice(26)}`;
}

async function verifyImplementation(proxy: string, name: string) {
  const implAddress = await getImplementation(proxy);
  console.log(`🔍 ${name} implementation address:`, implAddress);

  try {
    await run("verify:verify", {
      address: implAddress,
      constructorArguments: [],
    });
    console.log(`✅ Verified: ${name}`);
  } catch (e: any) {
    console.error(`❌ Verification failed for ${name}:`, e.message);
  }
}

async function main() {
  await verifyImplementation(CONTRACTS.BVP_STAKING, "BVPStakingUpgradeable");
  await verifyImplementation(CONTRACTS.GAS_ROUTER, "GasRouterUpgradeable");
}

main().catch(console.error);

