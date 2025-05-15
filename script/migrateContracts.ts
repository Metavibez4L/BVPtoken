import { ethers } from "hardhat";
import { getAddress } from "ethers"; // ✅ Normalize all addresses

async function main() {
  const [deployer] = await ethers.getSigners();

  // ✅ Normalize raw addresses into checksum format
  const BVP = getAddress("0x29d66a6bd99ca8846fb387e66759485e774411ac");
  const STAKING = getAddress("0x3a2b84d64c67ed134ce2d701b207e8c308d3bb64");
  const ROUTER = getAddress("0x4f4d9d7d75160025d5f2b15ea3d49641cefb834e");

  const token = await ethers.getContractAt("BVPToken", BVP);
  const staking = await ethers.getContractAt("BVPStaking", STAKING);
  const router = await ethers.getContractAt("GasRouter", ROUTER);

  const fundAmount = ethers.parseEther("2000");

  // ✅ Fund both contracts
  await token.transfer(ROUTER, fundAmount);
  console.log(`✅ Funded GasRouter with ${fundAmount} BVP`);

  await token.transfer(STAKING, fundAmount);
  console.log(`✅ Funded Staking with ${fundAmount} BVP`);

  const treasury = await router.treasury();
  console.log(`ℹ️  GasRouter treasury is set to: ${treasury}`);
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
