// hardhat.config.ts
import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
import * as dotenv from "dotenv";
dotenv.config();

const config: HardhatUserConfig = {
  solidity: "0.8.29",

  // point the TS test runner at your folder with *.test.ts
  paths: { tests: "./hardhat-tests" },

  networks: {
    hardhat: {
      chainId: 31337,
      accounts: { count: 10 },
    },
    arbitrumsepolia: {
      url: process.env.ARB_SEPOLIA_RPC_URL || "",
      chainId: 421614,
      accounts: process.env.PRIVATE_KEY ? [process.env.PRIVATE_KEY] : [],
    },
  },

  etherscan: {
    apiKey: {
      arbitrumSepolia: process.env.ARBISCAN_API_KEY || "",
    },
  },

  mocha: { timeout: 60000 },
};

export default config;
