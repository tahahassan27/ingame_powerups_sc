require("dotenv").config();
const { CUSTOM_TOKEN_ADDRESS, BASE_URI } = process.env;
const GamePowerUps = artifacts.require("GamePowerUps");
module.exports = async function (deployer) {
  await deployer.deploy(GamePowerUps, CUSTOM_TOKEN_ADDRESS, BASE_URI);
};
