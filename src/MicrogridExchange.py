from web3 import Web3, IPCProvider, HTTPProvider 
import json
import logging
from time import sleep

def connect_http(address='http://localhost:8545'):
    return Web3(HTTPProvider(address))

def bootstrap():
    ''' bootstrap is purely for testing - to be removed. '''
    web3 = connect_http()
    path = '../build/contracts/MicrogridExchange.json'

    new_contract = ContractFactory().factory(web3, path)
    mx = MicrogridExchange(web3, new_contract)

    return mx


class ContractFactory():
    ''' Factory function for MicrogridExchange '''
    def __init__(self):
        pass

    def factory(self, web3, local_contract_path):
        with open(local_contract_path, 'r') as contract_json:
            compiled_contract = json.loads(contract_json.read())

        contract = web3.eth.contract(
                abi=compiled_contract['abi'],
                bytecode=compiled_contract['bytecode']
        )

        return contract


class MicrogridExchange(object):
    ''' The MicrogridExchange class is designed to interact with the
        Exchange.sol Solidity contact. It maintains the contract as private
        data, and allows interaction with the public functions of the
        MicrogridExchange Contract.
    '''

    def __init__(self, web3, contract):
        self.contract = contract        # Compiled Microgrid.sol
        self.web3 = web3                # Current web3 client
        self.tx_microgrid_exchange = {  # microgrid_exchange tx info
                'from': self.web3.eth.coinbase,
                'gas' : 5000000,
                'to' : ''
        }

    def setMicrogridExchangeAddress(self, address):
        ''' Setter for the Microgrid Exchange contract transaction metadata 'to' address
            @modifiers ownerOnly
        '''
        self.tx_microgrid_exchange['to'] = address

    def listenValidationRequest(self):
        ''' listen for validationRequest events. Callback to validate function on event.
            If event is validated then approve the creation of KWH tokens.
        '''
        pass
        # Having a hell of a time with the event filtering.
        # Waiting for v4 to use contract.eventFilter
        # uhhhgggaaaaa

    def approveMint(self, asset_address, amount):
        ''' Approve the minting of kWh for asset address
            @modifiers ownerOnly
        '''
        tx_address = self.contract.transact(self.tx_microgrid_exchange).\
            approveMint(asset_address, amount)
        tx_receipt = self.web3.eth.getTransactionReceipt(tx_address)
        return tx_receipt

    def whitelistAsset(self, asset_address):
        ''' Adds asset_address to Microgrid Exchange whitelist. Whitelisted assets may call the Microgrid Exchange's
            public functions.
            @modifiers ownerOnly
        '''
        tx_address = self.contract.transact(self.tx_microgrid_exchange).\
            whitelistAsset(asset_address)
        tx_receipt = self.web3.eth.getTransactionReceipt(tx_address)
        return tx_receipt


if __name__ == '__main__':
    microgrid_exchange = bootstrap()
    microgrid_exchange.listenValidationRequest()
