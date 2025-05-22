import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
import "@nomicfoundation/hardhat-verify";
import * as dotenv from "dotenv";
dotenv.config();

const config: HardhatUserConfig = {
  solidity: { compilers: [{ version: "0.8.29" }] },
  networks: {
    arbitrumSepolia: {
      url: process.env.ARB_SEPOLIA_RPC_URL,
      accounts: [process.env.PRIVATE_KEY!]
    }
  },
  verify: {
    etherscan: {
      apiKey: process.env.ARBISCAN_API_KEY
    }
  }
};

export default config;
