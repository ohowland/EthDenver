pragma solidity ^0.4.18;

import "../../zeppelin-solidity/contracts/token/ERC20/BurnableToken.sol";
import "../../zeppelin-solidity/contracts/token/ERC20/MintableToken.sol";

contract MicrogridExchangeInterface is MintableToken, BurnableToken {
/* @title MicrogridExchangeInterface for MicrogridExchange ABI
 * @dev defines the interface for the MicrogridExchange contract
 * uses the MintableToken and (eventually) BurnableToken templates
 * from OpenZeppelin. 
 */

  event validateRequest(address _asset, uint256 _kwh);
  
  mapping (address => bool) public asset_whitelist;
  
  modifier whitelisted(address _asset) {
    require(asset_whitelist[_asset]);
    _;
  }

  /* @dev External function called by OperatorsAgreement contract.
   * device's request KWH tokens to be minted.
   */
  function requestMint(uint256 _amount_produced) external;

  /* @dev External function called by contract owner.
   * Calls the token minting function
   */
  function approveMint(address _asset, uint256 _amount_produced) external;
  

  /* @dev External function called by contract owner.
   * whitelisted assets are OperatorAgreement contracts with
   * the privledge to call requestMint
   */
  function whitelistAsset(address _asset) external; 
}

contract MicrogridExchange is MicrogridExchangeInterface {
  /* @title Implementaiton of the MicrogridExchange
   * @dev MicrogridExchange is at its core an ERC20 token repo.
  */
  function requestMint(uint256 _amount_produced) 
    external whitelisted(msg.sender) {
    
    /* @dev validate request off-chain */
    validateRequest(msg.sender, _amount_produced);
  }

  function approveMint(address _asset, uint256 _amount_produced) 
    external onlyOwner whitelisted(_asset) {
   
    /* thank you OpenZepplin! */ 
    mint(_asset, _amount_produced); 
  }
  
  function whitelistAsset(address _asset) external onlyOwner {
    asset_whitelist[_asset] = true;
  }

}

