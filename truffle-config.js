const PrivateKeyProvider = require("@truffle/hdwallet-provider");
const privateKey =
  "${PRIVATE_KEY}";
const privateKeyProvider = new PrivateKeyProvider(
  privateKey,
  "http://18.216.213.235:8545"
);
const fs = require("fs");

// provider: () => new HDWalletProvider(
module.exports = {
  // See <http://truffleframework.com/docs/advanced/configuration>
  // for more about customizing your Truffle configuration!
  networks: {
    besu: {
      protocol: "http",
      host: "18.216.213.235:8545",
      provider: privateKeyProvider,
      network_id: "*", // 211 for Freight Trust Network
    },
    compilers: {
      solc: {
        version: "^0.6.2",
      },
    },
  },
};
