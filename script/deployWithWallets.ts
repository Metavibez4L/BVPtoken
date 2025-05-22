import { ethers } from "hardhat";

async function main() {
  const [deployer] = await ethers.getSigners();
  console.log("Deployer:", deployer.address);

  const roles = [
    "PUBLIC_SALE",
    "OPERATIONS",
    "PRESALE",
    "FOUNDERS_TEAM",
    "MARKETING",
    "ADVISORS",
    "TREASURY_HOLD",
    "LIQUIDITY",
  ] as const;

  type Role = typeof roles[number];

  const wallets: Record<Role, ethers.Wallet> = {} as any;
  for (const role of roles) {
    wallets[role] = ethers.Wallet.createRandom().connect(ethers.provider);
    console.log(`${role} ➡ ${wallets[role].address} | PrivateKey: ${wallets[role].privateKey}`);
  }

  for (let i = 0; i < roles.length; i++) {
    const role = roles[i];
    const tx = await deployer.sendTransaction({
      to: wallets[role].address,
      value: ethers.parseEther("0.01"),
      nonce: await ethers.provider.getTransactionCount(deployer.address, "latest")
    });
    await tx.wait();
  }
  console.log("Funded all role wallets with 0.01 ETH");

  const BVP = await ethers.getContractFactory("BVPToken");
  const bvp = await BVP.deploy(
    wallets.PUBLIC_SALE.address,
    wallets.OPERATIONS.address,
    wallets.PRESALE.address,
    wallets.FOUNDERS_TEAM.address,
    wallets.MARKETING.address,
    wallets.ADVISORS.address,
    wallets.TREASURY_HOLD.address,
    wallets.LIQUIDITY.address
  );
  await bvp.waitForDeployment();
  console.log("BVPToken deployed to:", await bvp.getAddress());
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
