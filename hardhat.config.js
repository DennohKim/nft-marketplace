require('@nomiclabs/hardhat-waffle');

// Initialize `dotenv` with the `.config()` function
require('dotenv').config({ path: '.env' });

// Environment variables should now be available
// under `process.env`
const { PRIVATE_KEY } = process.env;
const { RPC_URL } = process.env;

// Show an error if environment variables are missing
if (!PRIVATE_KEY) {
  console.error('Missing PRIVATE_KEY environment variable');
}

if (!RPC_URL) {
  console.error('Missing RPC_URL environment variable');
}

// Add the alfajores network to the configuration
module.exports = {
  solidity: '0.8.4',
  networks: {
    alfajores: {
      url: RPC_URL,
      accounts: [PRIVATE_KEY],
    },
  },
};
