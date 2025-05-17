import { ethers } from "hardhat";
import * as dotenv from "dotenv";
import path from "path";

dotenv.config({ path: path.resolve(__dirname, "../.env") });

async function main() {
  const [deployer] = await ethers.getSigners();
  console.log("🔧 Deploying FeeTokenPricer from:", deployer.address);

  const nativeToken = process.env.NATIVE_TOKEN;
  if (!nativeToken) {
    throw new Error("Missing NATIVE_TOKEN in .env");
  }

  // Deploy ConstantFeeTokenPricer:
  // constructor(address _feeToken, uint256 _feeAmount)
  // Here we set a 1:1 rate (1 token per ETH gas unit).
  const Pricer = await ethers.getContractFactory("ConstantFeeTokenPricer");
  const pricer = await Pricer.deploy(
    nativeToken,
    ethers.utils.parseUnits("1", 18)
  );
  await pricer.deployed();

  console.log("📌 FeeTokenPricer deployed at:", pricer.address);
  console.log(`👉 Add to .env: FEE_TOKEN_PRICER=${pricer.address}`);
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
