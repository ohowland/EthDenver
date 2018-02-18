from web3 import Web3, IPCProvider, HTTPProvider

import json
import logging


''' HELPERS '''

def connect_http(address='http://localhost:8545'):
    return Web3(HTTPProvider(address))

def connect_testnet(path='/home/owen/.rinkeby/geth.ipc'):
    return Web3(IPCProvider(path))

def bootstrap():
    ''' bootstrap is purely for testing - to be removed. '''
    web3 = connect_http()
    path = '../build/contracts/OperatorsAgreement.json'

    new_contract = ContractFactory().factory(web3, path)
    oa = OperatorsAgreement(web3, new_contract)
    
    return oa

class Meter():
    ''' Meter Class used as context for the Device struct returned by the operator's agreement
        contains information about a device's total production and consumption.
    '''
    def __init__(self, args):
        self.wh_produced    = args[0]  # Totalized Wh export
        self.wh_consumed    = args[1]  # Totalized Wh import


class ContractFactory():
    ''' Factory for the OperatorsAgreement class '''

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


class OperatorsAgreement(object):
    ''' The OperatorsAgreement class is designed to interact with the
        OperatorsAgreement.sol Solidity contact. It maintains the contract as private
        data, and facilitates interaction with the public functions of the OperatorsAgreement Contract.
    '''

    def __init__(self, web3, contract):
        self.contract = contract         # Compiled Microgrid.sol
        self.web3 = web3                 # Current web3 client
        self.tx_operators_agreement = {  # operators_agreement tx info
                'from': self.web3.eth.coinbase,
                'gas' : 5000000,
                'to': ''
        }

        self.tx_microgrid_exchange = {   # microgrid_exchange tx info
                'from': self.web3.eth.coinbase,
                'gas' : 5000000,
                'to' : ''
        }

    def setOperatorsAgreementAddress(self, address):
        ''' Setter for the Operators Agreement contract transaction metadata 'to' address
            @modifiers ownerOnly
        '''
        self.tx_operators_agreement['to'] = address

    def setMicrogridExchangeAddress(self, address):
        ''' Setter for the Microgrid Exchange contract transaction metadata 'to' address
            @modifiers ownerOnly
        '''
        self.tx_microgrid_exchange['to'] = address
        self.setExchange(address)

    def setExchange(self, address):
        ''' The address of the Microgrid Exchange kept on-chain for Operator's contract.
            The contract owner MUST set this address before assets are able to communicate with the exchange.
            @modifiers ownerOnly
        '''
        tx_address = self.contract.transact(self.tx_operators_agreement).\
                setExchange(address)
        tx_receipt = self.web3.eth.getTransactionReceipt(tx_address)

        return tx_receipt

    def whitelistAsset(self, asset_address):
        ''' Whitelisted assets may interact with the contracts public functions.
            The asset must also be whitelisted by the Microgrid Exchange contract owner.
            @modifiers ownerOnly
        '''
        tx_address = self.contract.transact(self.tx_operators_agreement).\
            whitelistAsset(asset_address)
        tx_receipt = self.web3.eth.getTransactionReceipt(tx_address)
        return tx_receipt


    def generateKwh(self, kwh):
        ''' requests an updated energy production kwh on the Microgrid Exchange ledger
            @modifiers whitelisted
        '''
        tx_address = self.contract.transact(self.tx_operators_agreement).\
            generateKwh(kwh)
        tx_receipt = self.web3.eth.getTransactionReceipt(tx_address)
        return tx_receipt


if __name__ == '__main__':
    oa = bootstrap()

    oa.setMicrogridExchangeAddress(input('exchange: '))
    oa.setOperatorsAgreementAddress(input('operators: '))

    accounts = oa.web3.eth.accounts
    oa.whitelistAsset(accounts[0])



