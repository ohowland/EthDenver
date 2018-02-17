pragma solidity ^0.4.18;

import "../../EthDenver/contracts/Exchange.sol";
import "../../zeppelin-solidity/contracts/ownership/Ownable.sol";
import "../../zeppelin-solidity/contracts/math/SafeMath.sol";

/// @title The interface for a metering device.
contract MeterInterface is Ownable {
  
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

    // @dev Device's current designation as a consumer;
    bool valid_consumer;

    // @dev Device's current designation as a producer;
    bool valid_producer;
  }

  // @dev An address mapping to the Device struct.
  mapping (address => Device) public device_index;
  MicrogridExchangeInterface microgrid_exchange;

  // @dev assigns the right to produce to a device.
  function whitelistProducer(address _producer) external;

  // @dev assigns the right to consume to a device.
  function whitelistConsumer(address _consumer) external;
  
  // @dev Generate event log of kilowatt-hours generated.
  function generateKwh(uint256 _kwh) external;

  function setExchange(address _energy_exchange) external;
}

contract OperatorsAgreement is MeterInterface {
  using SafeMath for uint256;

  // @dev Event used to log the sender's ID and the am
  event logKwhGeneration(address _sender, uint256 _kwh);
  event logKwhConsumption(address _sender, uint256 _kwh);

  // @dev assigns the right to produce to a device
  function whitelistProducer(address _producer) external onlyOwner {
    device_index[_producer].valid_producer = true;
  }

  // @dev assigns the right to consume to a device.
  function whitelistConsumer(address _consumer) external onlyOwner {
    device_index[_consumer].valid_consumer = true;
  } 

  /** @dev Allow trusted device to log generated kwh with
    * microgrid exchange.
    * @param _kwh The current totalized production watt hours
    * @return Boolean if operation completes
    *
    */
  function generateKwh(uint256 _kwh) external {
    // @dev add the newly generated watt-hours to available for trade
    require(device_index[msg.sender].valid_producer);

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

