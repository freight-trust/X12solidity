const etherlime = require("etherlime-lib");
const InterchangeExample = require("../build/InterchangeExample.json");
const ethers = require("ethers");

const deploy = async (networks, secrets, etherscanApiKeys) => {
  const deployer = new etherlime.EtherlimeGanacheDeployer();
  const result = await deployer.deploy(InterchangeExample);
};

module.exports = {
  deploy,
};
