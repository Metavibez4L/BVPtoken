import { ethers } from "hardhat";

async function main() {
  const [deployer] = await ethers.getSigners();
  console.log("Deploying from:", deployer.address);

  const bvpTokenAddress = "0x8B79c656DFE9Ab86cDF4D270eE0910753b94368c";       // 🔁 Replace with your actual deployed BVP token address
  const treasuryAddress = deployer.address;                   // Or Gnosis Safe / vault address

  const GasRouter = await ethers.getContractFactory("GasRouter");
  const router = await GasRouter.deploy(bvpTokenAddress, treasuryAddress);
  await router.waitForDeployment();
  console.log("GasRouter deployed at:", await router.getAddress());
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
