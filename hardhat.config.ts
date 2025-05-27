import { HardhatUserConfig } from "hardhat/config";

// Hardhat plugins
import "@nomiclabs/hardhat-ethers";              // Adds Ethers.js support
import "@nomiclabs/hardhat-waffle";              // Adds Waffle for testing
import "hardhat-gas-reporter";                   // Reports gas usage per function/test
import "@nomicfoundation/hardhat-verify";        // Enables contract verification via Etherscan
import "solidity-coverage";                      // Provides test coverage reports

import * as dotenv from "dotenv";
dotenv.config(); // Load environment variables from .env

// Hardhat configuration
const config: HardhatUserConfig = {
  solidity: "0.8.29", // Solidity compiler version

  networks: {
    // Default local in-memory blockchain
    hardhat: {
      accounts: {
        count: 10 // Use 10 accounts for tests/dev (useful for multi-user scenarios)
      }
    },
    
    // Arbitrum Sepolia Testnet config
    arbitrumsepolia: {
      url: process.env.ARB_SEPOLIA_RPC_URL || "", // RPC URL from .env
      chainId: 421614,                             // Arbitrum Sepolia chain ID
      accounts: process.env.PRIVATE_KEY ? [process.env.PRIVATE_KEY] : [] // Use deployer private key if available
    }
  },

  // Etherscan verification config (for Arbitrum Sepolia)
  etherscan: {
    apiKey: {
      arbitrumSepolia: process.env.ARBISCAN_API_KEY || "" // API key for contract verification
    }
  },

  // Gas usage report settings
  gasReporter: {
    enabled: true,        // Toggle gas report generation
    currency: "USD"       // Display gas cost in USD
  }
};

export default config;
