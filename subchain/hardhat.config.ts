import { HardhatUserConfig } from "hardhat/config";
import "@nomiclabs/hardhat-ethers";
import * as dotenv from "dotenv";
dotenv.config({ path: "./.env" });

const { PRIVATE_KEY, ARB_SEPOLIA_RPC_URL } = process.env;

const config: HardhatUserConfig = {
  solidity: "0.8.29",
  defaultNetwork: "orbitSepolia",
  networks: {
    orbitSepolia: {
      url: ARB_SEPOLIA_RPC_URL,
      accounts: PRIVATE_KEY ? [PRIVATE_KEY] : [],
    },
  },
  paths: {
    sources:   "contracts",
    tests:     "test",
    cache:     "cache",
    artifacts: "artifacts",
  },
  external: {
    contracts: [{ artifacts: "util" }],
  },
};

export default config;
