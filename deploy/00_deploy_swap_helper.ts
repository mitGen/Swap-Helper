import { DeployFunction } from "hardhat-deploy/types";
import { typedDeployments } from "@utils";
import { DEPLOY } from "config";

const migrate: DeployFunction = async ({ deployments, getNamedAccounts }) => {
  const { deploy } = typedDeployments(deployments);
  const { deployer } = await getNamedAccounts();
  const { TWAP, ROUTER, DEVIATION } = DEPLOY;

  if (TWAP) {
    await deploy("SwapHelperV3TWAP", {
      from: deployer,
      args: [ROUTER, DEVIATION],
      log: true,
    });
  } else {
    await deploy("SwapHelperV3", {
      from: deployer,
      args: [ROUTER],
      log: true,
    });
  }
};

export default migrate;

migrate.tags = ["swap_helper"];
