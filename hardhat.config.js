/** @type import('hardhat/config').HardhatUserConfig */
require("@nomicfoundation/hardhat-foundry");

module.exports = {
  solidity: {
    version: "0.8.17",
    settings: {
      optimizer: {
        enabled: true,
        runs: 1000,
      },
    },
  },
};
