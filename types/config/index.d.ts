declare module "config" {
  export interface Node {
    readonly GAS_PRICE_NODE: number | "auto";
    readonly LOGGING: boolean;
    readonly FORK: Fork;
  }

  export interface Fork {
    readonly FORK_PROVIDER_URI: string;
    readonly FORK_ENABLED: boolean;
  }

  export interface GasReporter {
    readonly ENABLED: boolean;
    readonly COINMARKETCAP: string;
    readonly CURRENCY: string;
    readonly TOKEN: string;
    readonly GAS_PRICE_API: string;
  }

  export interface ContractSizer {
    readonly ALPHA_SHORT: boolean;
    readonly RUN_ON_COMPILE: boolean;
    readonly DISAMBIGUATE_PATHS: boolean;
    readonly STRICT: boolean;
    readonly ONLY: string[];
    readonly EXPECT: string[];
  }

  export const INFURA_KEY: string;
  export const ETHERSCAN_API_KEY: string;
  export const GAS_PRICE: number;
  export const NODE: Node;
  export const GAS_REPORTER: GasReporter;
  export const CONTRACT_SIZER: ContractSizer;
  export const DEPLOY: Deploy;
  export const SCRIPTS: Scripts;

  export interface Deploy {
    readonly DEPLOYER_KEY: string;
    readonly TWAP: boolean;
    readonly ROUTER: string;
    readonly DEVIATION: number | string;
  }

  export interface Scripts {
    readonly OPERATOR_KEY: string;
  }
}
