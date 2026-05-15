import "dotenv/config";
import "@nomicfoundation/hardhat-verify";

import hardhatToolboxMochaEthersPlugin from "@nomicfoundation/hardhat-toolbox-mocha-ethers";
import { configVariable, defineConfig } from "hardhat/config";

const config = defineConfig({
  plugins: [hardhatToolboxMochaEthersPlugin],
  solidity: {
    version: "0.8.28",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200,
      },
    },
  },
  networks: {
    sepolia: {
      type: "http",
      chainId: 11155111,
      chainType: "l1",
      url: configVariable("SEPOLIA_RPC_URL"),
      accounts: process.env.PRIVATE_KEY ? [process.env.PRIVATE_KEY] : [],
      timeout: 600000, // 超时时间设为 60 秒，解决 408 问题
      gasMultiplier: 1.2 // 适当提高 gas 上限，避免部署时 gas 不足
    },
  },
});

export default config;
