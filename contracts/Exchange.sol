pragma solidity ^0.4.18;

import "../../zeppelin-solidity/contracts/token/ERC20/BurnableToken.sol";
import "../../zeppelin-solidity/contracts/token/ERC20/MintableToken.sol";


contract MicrogridExchangeInterface is MintableToken, BurnableToken {
  /* @title MicrogridExchangeInterface for MicrogridExchange ABI
   * @dev defines the interface for the MicrogridExchange contract
   * uses the MintableToken and (eventually) BurnableToken templates
   * from OpenZeppelin. 
   */

  event validateRequest(address _asset, uint256 _kwh); // Asset updateTotalKw request event
  
  mapping (address => bool) public asset_whitelist; // Access to asset whitelist
  
  modifier whitelisted(address _asset) {
    require(asset_whitelist[_asset]);
    _;
  }

  function requestMint(uint256 _amount_produced) external;

  function approveMint(address _asset, uint256 _amount_produced) external;
  
  function whitelistAsset(address _asset) external; 
}


contract MicrogridExchange is MicrogridExchangeInterface {
  /* @title Implementaiton of the MicrogridExchange
   * @dev MicrogridExchange is at its core an ERC20 token repo.
   */
  
  function requestMint(uint256 _amount_produced) 
  external whitelisted(msg.sender) {
    /* @dev External function called by OperatorsAgreement contract.
     * device's request KWH tokens to be minted.
     */
    
    /* @dev validate request off-chain, call event to be picked up
     * by eventfilters.
     */
    validateRequest(msg.sender, _amount_produced);
  }

  function approveMint(address _asset, uint256 _amount_produced) 
  external onlyOwner whitelisted(_asset) {
    /* @dev External function called by contract owner.
     * Calls the token minting function
     */
   
    mint(_asset, _amount_produced); 
  }
  
  function whitelistAsset(address _asset) external onlyOwner {
    /* @dev External function called by contract owner.
     * whitelisted assets are OperatorAgreement contracts with
     * the privledge to call requestMint
     */

    asset_whitelist[_asset] = true;
  }

}

