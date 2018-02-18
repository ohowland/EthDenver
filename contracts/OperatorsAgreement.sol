pragma solidity ^0.4.18;

import "../../EthDenver/contracts/Exchange.sol";
import "../../zeppelin-solidity/contracts/ownership/Ownable.sol";
import "../../zeppelin-solidity/contracts/math/SafeMath.sol";


contract OperatorsAgreementInterface is Ownable {
  /* @title The interface for OperatorsAgreement 
   * @dev implements OpenZeppelin's Ownable
   */

  modifier whitelisted(address _asset) {
    require(asset_whitelist[_asset]); 
    _;
  }
  
  struct Asset { 
  /* @dev Asset struct contains the production/consumption data
   * attributed to a device.
   * @notice kwh is the standard units of energy kilowatt-hour
   */

    uint256 kwh_produced; // positive transfer of energy to bus
    uint256 kwh_consumed; // negative transfer of energy to bus
  }

  mapping (address => Asset) public asset_index;  // Access to Asset struct
  mapping (address => bool) public asset_whitelist; // Access to whitelist
  
  MicrogridExchangeInterface microgrid_exchange;    // MicrogridExchange ABI(?)

  function whitelistAsset(address _producer) external;

  function updateTotalKwh(uint256 _kwh) external;

  function setExchange(address _energy_exchange) external;
}


contract OperatorsAgreement is OperatorsAgreementInterface {
  /* @title The implementation of the OperatorsAgrrement 
   * @dev 
  */
  
  using SafeMath for uint256;

  event logKwhGeneration(address _sender, uint256 _kwh);  // Asset kwh generation event
  event logKwhConsumption(address _sender, uint256 _kwh); // Asset kwh consumption event
  event whitelistedAsset(address _asset);                 // Asset whitelisting event

  function whitelistAsset(address _asset) external onlyOwner {
    /* @dev whitelisting an asset allows it to create transactions
     * with the MicrogridExchange contract/.
     */
    
    asset_whitelist[_asset] = true;
    whitelistedAsset(_asset);
  }

  function updateTotalKwh(uint256 _kwh) external whitelisted(msg.sender) {
    /* @dev Allow trusted device to log generated kwh with
     * microgrid exchange.
     * @param _kwh The current totalized production watt hours
     */
    
    uint256 new_kwh = _kwh.sub(asset_index[msg.sender].kwh_produced);   
    microgrid_exchange.requestMint(new_kwh);

    asset_index[msg.sender].kwh_produced = _kwh;
    logKwhGeneration(msg.sender, _kwh);
  }

  function setExchange(address _energy_exchange) external onlyOwner {
    /* @dev sets the target MicroGrid exchange
     * @param the MicrogridExchange's deployed contract address
     */

    microgrid_exchange = MicrogridExchangeInterface(_energy_exchange);
  }

}
