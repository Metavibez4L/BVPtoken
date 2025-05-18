import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
import * as dotenv from "dotenv";
dotenv.config();

// Pull in and validate required env vars
const {
  ETH_SEPOLIA_RPC_URL,
  ARB_SEPOLIA_RPC_URL,
  PRIVATE_KEY
} = process.env;

if (!ETH_SEPOLIA_RPC_URL || !ARB_SEPOLIA_RPC_URL || !PRIVATE_KEY) {
  throw new Error(
    "Missing .env vars. Make sure ETH_SEPOLIA_RPC_URL, ARB_SEPOLIA_RPC_URL & PRIVATE_KEY are set"
  );
}

const config: HardhatUserConfig = {
  defaultNetwork: "arbitrumSepolia",
  solidity: {
    compilers: [
      {
        version: "0.8.29",
        settings: { optimizer: { enabled: true, runs: 200 } }
      }
    ]
  },
  networks: {
    // L1: Ethereum Sepolia
    sepolia: {
      url: ETH_SEPOLIA_RPC_URL,
      accounts: [PRIVATE_KEY]
    },
    // L2: Arbitrum Sepolia
    arbitrumSepolia: {
      url: ARB_SEPOLIA_RPC_URL,
      accounts: [PRIVATE_KEY]
    }
  },
  paths: {
    sources: "./contracts",
    tests: "./test",
    cache: "./cache",
    artifacts: "./artifacts"
  },
  mocha: {
    timeout: 200_000
  }
};

export default config;
