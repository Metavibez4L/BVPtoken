import { HardhatUserConfig } from "hardhat/config";

// Hardhat plugins
import "@nomiclabs/hardhat-ethers";
import "@nomiclabs/hardhat-waffle";
import "hardhat-gas-reporter";
import "@nomicfoundation/hardhat-verify";
import "solidity-coverage";

import * as dotenv from "dotenv";
dotenv.config();

const config: HardhatUserConfig = {
  solidity: "0.8.29",

  networks: {
    hardhat: {
      accounts: {
        count: 10
      }
    },

    arbitrumsepolia: {
      url: process.env.ARB_SEPOLIA_RPC_URL || "",
      chainId: 421614,
      accounts: process.env.PRIVATE_KEY ? [process.env.PRIVATE_KEY] : []
    }
  },

  etherscan: {
    apiKey: {
      arbitrumSepolia: process.env.ARBISCAN_API_KEY || ""
    }
  },

  gasReporter: {
    enabled: true,
    currency: "USD"
  }
};

export default config;
