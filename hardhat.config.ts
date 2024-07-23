import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
import "dotenv/config";

const config: HardhatUserConfig = {
  solidity: "0.8.24",
  networks: {
    fraxtalMainnet: {
      url: "https://rpc.frax.com",
      accounts: [`0x${process.env.PRIVATE_KEY}`],
      chainId: 252,
    },
    fraxtalTestnet: {
      url: "https://rpc.testnet.frax.com",
      accounts: [`0x${process.env.PRIVATE_KEY}`],
      chainId: 2522,
    },
  },
};

export default config;
