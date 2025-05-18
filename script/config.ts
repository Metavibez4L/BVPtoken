// scripts/config.ts
import * as dotenv from "dotenv";
dotenv.config();

export const RPC_URL = process.env.ARB_SEPOLIA_RPC_URL || "";
export const PRIVATE_KEY = process.env.PRIVATE_KEY || "";

export const CONTRACTS = {
  BVP_TOKEN: process.env.BVP_TOKEN_ADDRESS || "",
  BVP_STAKING: process.env.BVP_STAKING_ADDRESS || "",
  GAS_ROUTER: process.env.GAS_ROUTER_ADDRESS || "",
};

if (!RPC_URL || !PRIVATE_KEY || !CONTRACTS.BVP_TOKEN) {
  throw new Error("Missing required environment variables in .env file");
}
