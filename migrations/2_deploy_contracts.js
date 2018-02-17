const MicrogridExchange = artifacts.require("MicrogridExchange");
const OperatorsAgreement = artifacts.require("OperatorsAgreement");

module.exports = function(deployer) {
  deployer.deploy(MicrogridExchange);
  deployer.deploy(OperatorsAgreement);
};

