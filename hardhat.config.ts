// hardhat.config.ts
import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
import * as dotenv from "dotenv";
dotenv.config();

const config: HardhatUserConfig = {
  solidity: "0.8.29",
  paths: { tests: "./hardhat-tests" },
  networks: {
    hardhat: { chainId: 31337, accounts: { count: 10 } },
    arbitrumsepolia: {
      url: process.env.ARB_SEPOLIA_RPC_URL || "",
      chainId: 421614,
      accounts: process.env.PRIVATE_KEY ? [process.env.PRIVATE_KEY] : [],
    },
  },
  etherscan: {
    // Etherscan V2: single key used for all networks (incl. Arbiscan)
    apiKey: process.env.ETHERSCAN_API_KEY || "",
  },
  // Optional: hide Sourcify “disabled” message (or set enabled: true to use it)
  sourcify: { enabled: false },
  mocha: { timeout: 60000 },
};

export default config;
