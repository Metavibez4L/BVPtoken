// subchain/scripts/deploy-chain.ts

import dotenv from "dotenv";
dotenv.config(); // load subchain/.env

console.log("Working directory:", process.cwd());
console.log("ENV VARS:");
[
  "PRIVATE_KEY",
  "PARENT_CHAIN_RPC_URL",
  "CHAIN_ID",
  "OWNER_ADDRESS",
  "VALIDATORS",
  "BATCH_POSTERS",
  "NATIVE_TOKEN",
  "FEE_TOKEN_PRICER",
].forEach((key) => {
  console.log(`  ${key}=${process.env[key]}`);
});


// Debug: print cwd and env vars
console.log("cwd:", process.cwd());
console.log("Loaded ENV:", {
  PRIVATE_KEY: process.env.PRIVATE_KEY,
  PARENT_CHAIN_RPC_URL: process.env.PARENT_CHAIN_RPC_URL,
  CHAIN_ID: process.env.CHAIN_ID,
  OWNER_ADDRESS: process.env.OWNER_ADDRESS,
  VALIDATORS: process.env.VALIDATORS,
  BATCH_POSTERS: process.env.BATCH_POSTERS,
  NATIVE_TOKEN: process.env.NATIVE_TOKEN,
  FEE_TOKEN_PRICER: process.env.FEE_TOKEN_PRICER,
});

import {
  prepareChainConfig,
  createRollupPrepareDeploymentParamsConfig,
  createRollup,
} from "@arbitrum/orbit-sdk";
import { createPublicClient, http } from "viem";
import { arbitrumSepolia } from "viem/chains";
import { privateKeyToAccount } from "viem/accounts";

async function main() {
  const {
    PRIVATE_KEY,
    PARENT_CHAIN_RPC_URL,
    CHAIN_ID,
    OWNER_ADDRESS,
    VALIDATORS,
    BATCH_POSTERS,
    NATIVE_TOKEN,
    FEE_TOKEN_PRICER,
  } = process.env;

  if (
    !PRIVATE_KEY ||
    !PARENT_CHAIN_RPC_URL ||
    !CHAIN_ID ||
    !OWNER_ADDRESS ||
    !VALIDATORS ||
    !BATCH_POSTERS ||
    !NATIVE_TOKEN ||
    !FEE_TOKEN_PRICER
  ) {
    throw new Error(
      "Missing required env var. See the debug output above for what was loaded."
    );
  }

  // 1) Prepare account
  const deployer = privateKeyToAccount(
    (`0x${PRIVATE_KEY}`) as `0x${string}`
  );

  // 2) Parent-chain client
  const parentClient = createPublicClient({
    chain: arbitrumSepolia,
    transport: http(PARENT_CHAIN_RPC_URL),
  });

  // 3) Parse IDs
  const chainIdNum = Number(CHAIN_ID);
  const chainIdBig = BigInt(CHAIN_ID);

  // 4) Build basic config
  const chainConfig = prepareChainConfig({
    chainId: chainIdNum,
    arbitrum: {
      InitialChainOwner: OWNER_ADDRESS as `0x${string}`,
      DataAvailabilityCommittee: false,
    },
  });

  // 5) Build full RollupDeploymentParams.Config
  const rollupParamsConfig =
    await createRollupPrepareDeploymentParamsConfig(parentClient, {
      chainId: chainIdBig,
      owner: OWNER_ADDRESS as `0x${string}`,
      chainConfig,
    });

  // 6) Prepare arrays & tokens
  const validators = VALIDATORS.split(",").map((v) => v.trim() as `0x${string}`);
  const batchPosters = BATCH_POSTERS.split(",").map(
    (b) => b.trim() as `0x${string}`
  );
  const nativeToken = NATIVE_TOKEN as `0x${string}`;
  const feeTokenPricer = FEE_TOKEN_PRICER as `0x${string}`;

  // 7) Deploy
  const results = await createRollup({
    params: {
      config: rollupParamsConfig,
      validators,
      batchPosters,
      nativeToken,
      feeTokenPricer,
    },
    account: deployer,
    parentChainPublicClient: parentClient,
  });

  console.log("✅ Core contracts deployed:", results.coreContracts);
  console.log(
    "🚀 Deployment TX hash:",
    results.transactionReceipt.transactionHash
  );
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
