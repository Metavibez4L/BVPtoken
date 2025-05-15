import { ethers } from "hardhat";

async function main() {
  const [deployer] = await ethers.getSigners();
  const user = deployer; // Using deployer as test user

  // ✅ Deployed contract addresses on Arbitrum Sepolia
  const BVP_ADDRESS = "0x29D66A6bD99CA8846FB387e66759485E774411ac";
  const GAS_ROUTER_ADDRESS = "0x4f4d9d7D75160025D5f2B15Ea3d49641cEfB834E";

  const token = await ethers.getContractAt("IERC20", BVP_ADDRESS);
  const gasRouter = await ethers.getContractAt("GasRouter", GAS_ROUTER_ADDRESS);

  const testAmount = ethers.parseEther("1000"); // 1000 BVP

  // 🔁 Ensure user has enough tokens
  const fundTx = await token.transfer(user.address, testAmount);
  await fundTx.wait();
  console.log("✅ Funded user with 1000 BVP");

  // ✅ Pre-fund GasRouter with extra BVP to handle split (2000 to be safe)
  const seedTx = await token.transfer(GAS_ROUTER_ADDRESS, ethers.parseEther("2000"));
  await seedTx.wait();
  console.log("✅ Pre-funded GasRouter with 2000 BVP");

  // ✅ Approve GasRouter to spend user's 1000 BVP
  const approveTx = await token.approve(GAS_ROUTER_ADDRESS, testAmount);
  await approveTx.wait();
  console.log("✅ Approved GasRouter to spend 1000 BVP");

  // ✅ Call handleGas to trigger 20/80 split
  const tx = await gasRouter.handleGas(testAmount);
  const receipt = await tx.wait();
  console.log("✅ handleGas executed");
  console.log("TX hash:", receipt.hash);
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
