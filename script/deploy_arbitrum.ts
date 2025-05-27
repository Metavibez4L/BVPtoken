import { ethers } from "hardhat";

async function main() {
  const [deployer] = await ethers.getSigners();
  console.log("🚀 Deploying from:", deployer.address);

  // ✅ Fully controlled allocation addresses
  const publicSale      = "0x0aE398b8d97c61Aa62f94E410d41C71992d107Ee";
  const operations      = "0x3A60b07d31cb9436810A2aE4c842F2762fa4114B";
  const presale         = "0x73715c6751aE4baeDDa3f0ae0A9b8C77444B3696";
  const foundersAndTeam = "0xf6e353e1D97615d38200A576Ae0011f96Ad59D25";
  const marketing       = "0x0Ba15d9572ed6897db101fbF41b311bfdb5010a3";
  const advisors        = "0x11E71f5b379af2b79c7e751b6435Ca29c3805Ec9";
  const treasury        = "0xf698e151cFDb7138Fb5F311739865f9435Ee44d6";
  const liquidity       = "0x5Fd8fDcc9F225D246f863F3a5A0e43005C438270"; // ✅ corrected

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
