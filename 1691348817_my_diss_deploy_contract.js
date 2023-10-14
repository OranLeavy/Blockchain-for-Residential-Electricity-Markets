// This file was used in VSCode for migrating the final smart contract
// Migration file: “1691348817_my_diss_deploy_contract” file: 
const Token = artifacts.require("Token"); // Adjust the contract name based on the actual artifact file name

module.exports = function(deployer) {
  deployer.deploy(Token); // Deploy the contract
};