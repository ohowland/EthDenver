pragma solidity ^0.4.18;

import "../../EthDenver/contracts/Exchange.sol";
import "../../zeppelin-solidity/contracts/ownership/Ownable.sol";
import "../../zeppelin-solidity/contracts/math/SafeMath.sol";

/// @title The interface for a metering device.
contract MeterInterface is Ownable {
  
  modifier whitelisted(address _asset) {
    // require(asset_whitelist[_asset]); // Comment out for testing
    _;
  }
  
  /* @dev The device contains all the production information about a meter.
   * note that kwh is the standard units of energy Kilo-Watt-Hour
   */
  struct Device { 
    // @dev kwh_produced is the positive transfer of energy from the
    // device to the bus.
    uint256 kwh_produced;

    // @dev kwh_consumed is the positive transfer of energy from the bus
    // to the device.
    uint256 kwh_consumed;
  }

  // @dev An address mapping to the Device struct.
  mapping (address => Device) public device_index;
  mapping (address => bool) public asset_whitelist;
  MicrogridExchangeInterface microgrid_exchange;

  // @dev assigns the right to produce to a device.
  function whitelistAsset(address _producer) external;

  // @dev Generate event log of kilowatt-hours generated.
  function generateKwh(uint256 _kwh) external;

  // @dev Set's the target microgrid exchange contract address
  function setExchange(address _energy_exchange) external;
}

contract OperatorsAgreement is MeterInterface {
  using SafeMath for uint256;

  // @dev Event used to log the sender's ID and the am
  event logKwhGeneration(address _sender, uint256 _kwh);
  event logKwhConsumption(address _sender, uint256 _kwh);
  event whitelistedAsset(address _asset);

  // @dev assigns the right to produce to a device
  function whitelistAsset(address _asset) external onlyOwner {
    asset_whitelist[_asset] = true;
    whitelistedAsset(_asset);
  }

  /** @dev Allow trusted device to log generated kwh with
    * microgrid exchange.
    * @param _kwh The current totalized production watt hours
    * @return Boolean if operation completes
    *
    */
  function generateKwh(uint256 _kwh) external whitelisted(msg.sender) {

    // @dev kwh are a totalized counter, find the latest kwh generated.
    // @notice the roll over must be dealt with gracefully.
    uint256 new_kwh = _kwh.sub(device_index[msg.sender].kwh_produced);   

    // @dev Call the external microgrid exchange contract  
    microgrid_exchange.requestMint(new_kwh);

    device_index[msg.sender].kwh_produced = _kwh;
    logKwhGeneration(msg.sender, _kwh);
  }
  
  function setExchange(address _energy_exchange) external onlyOwner {
    microgrid_exchange = MicrogridExchangeInterface(_energy_exchange);
  }

}
