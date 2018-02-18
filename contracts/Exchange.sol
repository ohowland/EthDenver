pragma solidity ^0.4.18;

import "../../zeppelin-solidity/contracts/token/ERC20/BurnableToken.sol";
import "../../zeppelin-solidity/contracts/token/ERC20/MintableToken.sol";

/** @dev AccessControl contract designates a commissioner who assigns devices
  * the right to post consumption/production and trade on contract network
  * credit to the CryptoKitties team for this implementation.
  */

contract MicrogridExchangeInterface is MintableToken, BurnableToken {
  
  event validateRequest(address _asset, uint256 _kwh);
  
  mapping (address => bool) public asset_whitelist;
  
  modifier whitelisted(address _asset) {
    // require(asset_whitelist[_asset]); // Comment out for testing
    _;
  }

  function requestMint(uint256 _amount_produced) external;

  function approveMint(address _asset, uint256 _amount_produced) external;
  
  function whitelistAsset(address _asset) external; 
}

contract MicrogridExchange is MicrogridExchangeInterface {
  
  function requestMint(uint256 _amount_produced) 
           external whitelisted(msg.sender) {
    
    // validate request off-chain
    validateRequest(msg.sender, _amount_produced);
  }

  function approveMint(address _asset, uint256 _amount_produced) 
           external onlyOwner whitelisted(_asset) {
    
    // mint kwh tokens
    mint(_asset, _amount_produced); 
  }
  
  function whitelistAsset(address _asset) external onlyOwner {
    asset_whitelist[_asset] = true;
  }

}

