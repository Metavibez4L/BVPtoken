import { ethers } from "hardhat";

async function main() {
  const [deployer] = await ethers.getSigners();
  console.log("🚀 Deploying from:", deployer.address);

  // Use randomly generated addresses as recipients (for testing/demo)
  const dummy = () => ethers.Wallet.createRandom().address;

  const publicSale       = dummy();
  const operations       = dummy();
  const presale          = dummy();
  const foundersAndTeam  = dummy();
  const marketing        = dummy();
  const advisors         = dummy();
  const treasury         = dummy();
  const liquidity        = dummy();

  // === Deploy BVPToken ===
  const BVPToken = await ethers.getContractFactory("BVPToken");
  const token = await BVPToken.deploy(
    publicSale,
    operations,
    presale,
    foundersAndTeam,
    marketing,
    advisors,
    treasury,
    liquidity
  );
  await token.deployed();
  console.log("✅ BVPToken deployed at:", token.address);

  // === Deploy BVPStaking ===
  const BVPStaking = await ethers.getContractFactory("BVPStaking");
  const staking = await BVPStaking.deploy(token.address);
  await staking.deployed();
  console.log("✅ BVPStaking deployed at:", staking.address);

  console.log("\n📜 Deployment complete:");
  console.log(" - BVPToken       :", token.address);
  console.log(" - BVPStaking     :", staking.address);
  console.log(" - Public Sale    :", publicSale);
  console.log(" - Operations     :", operations);
  console.log(" - Presale        :", presale);
  console.log(" - Founders/Team  :", foundersAndTeam);
  console.log(" - Marketing      :", marketing);
  console.log(" - Advisors       :", advisors);
  console.log(" - Treasury       :", treasury);
  console.log(" - Liquidity      :", liquidity);
}

main().catch((error) => {
  console.error("❌ Deployment failed:", error);
  process.exitCode = 1;
});
