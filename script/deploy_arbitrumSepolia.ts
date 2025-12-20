import { ethers, run } from "hardhat";
import { mkdirSync, writeFileSync } from "fs";
import { join } from "path";

async function verify(address: string, args: any[]) {
  try {
    await run("verify:verify", { address, constructorArguments: args });
    console.log(`✅ Verified: ${address}`);
  } catch (err: any) {
    if (err.message.includes("Already Verified")) {
      console.log(`ℹ️  Already verified: ${address}`);
    } else {
      console.log(`⚠️  Verification skipped: ${err.message}`);
    }
  }
}

async function main() {
  const [deployer] = await ethers.getSigners();
  console.log("🚀 Deploying from:", deployer.address);

  // ✅ Allocation addresses (Sepolia testnet versions)
  const publicSale      = "0x0aE398b8d97c61Aa62f94E410d41C71992d107Ee";
  const operations      = "0x3A60b07d31cb9436810A2aE4c842F2762fa4114B";
  const presale         = "0x73715c6751aE4baeDDa3f0ae0A9b8C77444B3696";
  const foundersAndTeam = "0xf6e353e1D97615d38200A576Ae0011f96Ad59D25";
  const marketing       = "0x0Ba15d9572ed6897db101fbF41b311bfdb5010a3";
  const advisors        = "0x11E71f5b379af2b79c7e751b6435Ca29c3805Ec9";
  const treasury        = "0xf698e151cFDb7138Fb5F311739865f9435Ee44d6";
  const liquidity       = "0x5Fd8fDcc9F225D246f863F3a5A0e43005C438270";

  // === Deploy BVPToken ===
  const BVPToken = await ethers.getContractFactory("BVPToken");
  const tokenArgs = [
    publicSale,
    operations,
    presale,
    foundersAndTeam,
    marketing,
    advisors,
    treasury,
    liquidity
  ];
  const token = await BVPToken.deploy(...tokenArgs);
  await token.waitForDeployment();
  const tokenAddress = await token.getAddress();
  console.log("✅ BVPToken deployed at:", tokenAddress);

  // === Deploy BVPStaking ===
  const BVPStaking = await ethers.getContractFactory("BVPStaking");
  const stakingArgs = [tokenAddress];
  const staking = await BVPStaking.deploy(...stakingArgs);
  await staking.waitForDeployment();
  const stakingAddress = await staking.getAddress();
  console.log("✅ BVPStaking deployed at:", stakingAddress);

  console.log("\n📜 Deployment Summary:");
  console.log(" - BVPToken   :", tokenAddress);
  console.log(" - BVPStaking :", stakingAddress);

  // === Verify both ===
  await verify(tokenAddress, tokenArgs);
  await verify(stakingAddress, stakingArgs);

  // === Persist deployment metadata ===
  const outDir = join(__dirname, "..", "deployments");
  mkdirSync(outDir, { recursive: true });

  const deployment = {
    network: "arbitrum-sepolia",
    chainId: 421614,
    deployer: deployer.address,
    contracts: {
      BVPToken: {
        address: tokenAddress,
        verified: true,
      },
      BVPStaking: {
        address: stakingAddress,
        verified: true,
      },
    },
    allocationRecipients: {
      PublicSale: publicSale,
      Operations: operations,
      Presale: presale,
      FoundersAndTeam: foundersAndTeam,
      Marketing: marketing,
      Advisors: advisors,
      Treasury: treasury,
      Liquidity: liquidity,
    },
    verification: {
      arbiscan: true,
      urls: {
        BVPToken: `https://sepolia.arbiscan.io/address/${tokenAddress}#code`,
        BVPStaking: `https://sepolia.arbiscan.io/address/${stakingAddress}#code`,
      },
    },
  };

  const outPath = join(outDir, "arbitrum-sepolia.json");
  writeFileSync(outPath, JSON.stringify(deployment, null, 2));
  console.log(`📝 Wrote deployment metadata to deployments/arbitrum-sepolia.json`);
}

main().catch((error) => {
  console.error("❌ Deployment failed:", error);
  process.exitCode = 1;
});
