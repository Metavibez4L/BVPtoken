import { ethers } from "hardhat";

async function main() {
  const [deployer] = await ethers.getSigners();
  const user = deployer;

  // ✅ Latest deployed contracts on Arbitrum Sepolia
  const BVP = "0x153885400fDD14c200ba9913Ec1110376c9ff27E";
  const STAKING = "0xeeE33547B85a9E48e5E6Ef8D017865E6710ECAc4";
  const ROUTER = "0x1a6D7C3Ea4Ef352E4943b9AE8f6031fe302bDaF1";

  const token = await ethers.getContractAt("BVPToken", BVP);
  const staking = await ethers.getContractAt("BVPStaking", STAKING);
  const gasRouter = await ethers.getContractAt("GasRouter", ROUTER);

  const testAmount = ethers.parseEther("1000");

  // === TOKEN TESTS ===
  const totalSupply = await token.totalSupply();
  console.log("✅ BVP Total Supply:", totalSupply.toString());

  const initBalance = await token.balanceOf(user.address);
  console.log("✅ BVP User Balance:", initBalance.toString());

  // === GAS ROUTER TEST ===
  await token.approve(ROUTER, testAmount);
  await gasRouter.handleGas(testAmount);
  console.log("✅ GasRouter handleGas split processed");

  const treasury = await gasRouter.treasury();
  const treasuryBalance = await token.balanceOf(treasury);
  console.log("ℹ️  Treasury address:", treasury);
  console.log("💰 Treasury BVP balance:", treasuryBalance.toString());

  // === STAKING TEST ===
  const stakeState = await staking.stakes(user.address);

  if (stakeState.amount > 0) {
    console.log("⚠️  User already has an active stake. Skipping new stake.");
  } else {
    await token.approve(STAKING, testAmount);
    await staking.stake(testAmount);
    console.log("✅ User staked 1000 BVP");
  }

  // ⏩ Skip time simulation on real L2
  console.log("⚠️  Skipping unlock due to testnet time restrictions");

  const tier = await staking.getTier(user.address);
  console.log("✅ Tier (current):", tier);
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
