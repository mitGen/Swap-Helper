import "@nomicfoundation/hardhat-toolbox";
import "@nomicfoundation/hardhat-foundry";

import "tsconfig-paths/register";
import "hardhat-contract-sizer";
import "hardhat-watcher";
import "hardhat-deploy";

import "./tasks/index";

import { HardhatUserConfig } from "hardhat/config";
import {
  SCRIPTS,
  INFURA_KEY,
  ETHERSCAN_API_KEY,
  GAS_PRICE,
  NODE,
  GAS_REPORTER,
  CONTRACT_SIZER,
  DEPLOY,
} from "config";

const { DEPLOYER_KEY } = DEPLOY;
const { OPERATOR_KEY } = SCRIPTS;
const { FORK_PROVIDER_URI, FORK_ENABLED } = NODE.FORK;

function typedNamedAccounts<T>(namedAccounts: { [key in string]: T }) {
  return namedAccounts;
}

const config: HardhatUserConfig = {
  solidity: {
    compilers: [
      {
        version: "0.8.23",
        settings: {
          evmVersion: "paris",
          viaIR: true,
          optimizer: {
            enabled: true,
            runs: 200,
          },
        },
      },
    ],
  },
  typechain: {
    outDir: "types/typechain-types",
  },
  networks: {
    hardhat: {
      gasPrice: NODE.GAS_PRICE_NODE,
      loggingEnabled: NODE.LOGGING,
      forking: {
        url: FORK_PROVIDER_URI,
        enabled: FORK_ENABLED,
      },
    },
    localhost: {
      url: "http://127.0.0.1:8545",
    },
    mainnet: {
      url: `https://mainnet.infura.io/v3/${INFURA_KEY}`,
      chainId: 1,
      accounts: [DEPLOYER_KEY, OPERATOR_KEY],
    },
    goerli: {
      url: `https://goerli.infura.io/v3/${INFURA_KEY}`,
      chainId: 5,
      accounts: [DEPLOYER_KEY, OPERATOR_KEY],
    },
  },
  etherscan: {
    apiKey: {
      mainnet: ETHERSCAN_API_KEY,
      goerli: ETHERSCAN_API_KEY,
    },
  },
  namedAccounts: typedNamedAccounts({
    deployer: 0,
    operator: 1,
  }),
  watcher: {
    test: {
      tasks: [{ command: "test", params: { testFiles: ["{path}"] } }],
      files: ["./tests/**/*"],
      verbose: true,
    },
  },
  gasReporter: {
    enabled: GAS_REPORTER.ENABLED,
    coinmarketcap: GAS_REPORTER.COINMARKETCAP,
    currency: GAS_REPORTER.CURRENCY,
    token: GAS_REPORTER.TOKEN,
    gasPrice: GAS_PRICE,
  },
  contractSizer: {
    alphaSort: CONTRACT_SIZER.ALPHA_SHORT,
    runOnCompile: CONTRACT_SIZER.RUN_ON_COMPILE,
    disambiguatePaths: CONTRACT_SIZER.DISAMBIGUATE_PATHS,
    strict: CONTRACT_SIZER.STRICT,
    only: CONTRACT_SIZER.ONLY,
    except: CONTRACT_SIZER.EXPECT,
  },
};

export default config;
