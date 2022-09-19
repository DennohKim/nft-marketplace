const fs = require('fs');
require('@nomiclabs/hardhat-waffle');

// Provide access to privatekey
const privateKey = fs.readFileSync('.secret').toString().trim();

module.exports = {
  networks: {
    hardhat: {
      chainId: 1337,
    },
  },
  solidity: '0.8.4',
};
