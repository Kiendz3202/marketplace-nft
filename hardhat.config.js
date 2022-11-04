require('@nomicfoundation/hardhat-toolbox');
require('dotenv').config();
/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
	solidity: '0.8.17',
	defaultNetwork: 'hardhat',
	networks: {
		localhost: {
			url: 'http://127.0.0.1:8545/',
			chainId: 31337,
		},
		goerli: {
			url: process.env.GOERLI_RPC_URL,
			chainId: 5,
			accounts: [process.env.PRIVATE_KEY],
		},
		bsctest: {
			url: 'https://data-seed-prebsc-1-s1.binance.org:8545',
			accounts: [process.env.PRIVATE_KEY],
			chainId: 97,
			gasPrice: 10000000000,
			blockGasLimit: 1000000,
		},
	},
};
