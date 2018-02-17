from web3 import Web3, IPCProvider, HTTPProvider 
from solc import compile_source

def connect_ipc(path='/home/owen/dev/private-chain/chain-data/geth.ipc'):
    return Web3(IPCProvider(path))

def connect_http(address='http://localhost:8545'):
    return Web3(HTTPProvider(address))

def connect_testnet(path='/home/owen/.rinkeby/geth.ipc'):
    return Web3(IPCProvider(path))

def bootstrap_test():
    web3 = connect_http()
    path = 'contracts/Microgrid.sol'

    new_contract = ContractFactory().factory(web3, path)
    mc = MicrogridContract(web3, new_contract)
    
    return mc

''' Meter Class used as context for production and energy
    availability status posted on-chain
'''
class Meter():
    def __init__(self, args):
        self.wh_produced    = args[0]  # Totalized Wh export
        self.wh_consumed    = args[1]  # Totalized Wh import
        self.wh_available   = args[2]  # Wh available for trade
        self.wh_deficit     = args[3]  # Wh required for settlement
        self.valid_consumer = args[4]  # Device can post consumption
        self.valid_producer = args[5]  # Device can post production

''' Contract factory for compiling and creating the microgrid contract
'''
class ContractFactory():
    def __init__(self):
        pass

    def factory(self, web3, local_contract_path):
        with open(local_contract_path, 'r') as contract_src_file:
            compiled_contract = compile_source(contract_src_file.read())
  
        ''' Assuming the contract to deploy shares the same name
            as the contract file itself
        '''
        contract_name = local_contract_path.split('/')[-1][:-4]
        contract_interface = compiled_contract[
                '<stdin>:{}'.format(contract_name)
        ]

        contract = web3.eth.contract(
                abi=contract_interface['abi'], 
                bytecode=contract_interface['bin']
        )

        return contract


''' The MicrogridContract class is designed to interact with the 
    Meter.sol Solidity contact. It maintains the contract as private 
    data, and allows interaction with the public functions of the 
    MicrogridContract.
'''
class MicrogridContract(object):
    def __init__(self, web3, contract):
        self.contract = contract  # Compiled Microgrid.sol
        self.web3 = web3          # Current web3 client
        self.tx_info = {          # Standard tx_info
                'from': self.web3.eth.coinbase,
                'gas' : 5000000
            }
    
        self.deploy();

    """ Deploy contract at path using client"""
    def deploy(self):
        
        tx_address = self.contract.deploy(self.tx_info)

        tx_receipt = self.web3.eth.getTransactionReceipt(tx_address)
        self.contract.address = tx_receipt['contractAddress']
        
        return tx_receipt

    ''' ceoAddress: Getter for CEO's address
        @returns: current CEO's address
    '''
    def ceoAddress(self):
        return self.contract.call().ceo_address() 

    ''' getDevice: Getter for device_index map
        @param address: The device's address
        @return: Device information
    '''
    def getDevice(self, address):
        device = self.contract.call().device_index(address)
        return Meter(device)
    
    ''' setCEO: transfers the title of CEO to new address.
        This can only be done by current CEO.
        @params new_ceo: Address of new CEO
        @returns: tx_receipt
    '''
    def setCEO(self, new_ceo):
        tx_address = self.contract.transact(self.tx_info).\
                setCEO(new_ceo)
        tx_receipt = self.web3.eth.getTransactionReceipt(tx_address)
        return tx_receipt

    def designateProducer(self, producer_address):
        tx_address = self.contract.transact(self.tx_info).\
                designateProducer(producer_address)
        tx_receipt = self.web3.eth.getTransactionReceipt(tx_address)
        return tx_receipt

    def designateConsumer(self, consumer_address):
        tx_address = self.contract.transact(self.tx_info).\
                designateConsumer(consumer_address)
        tx_receipt = self.web3.eth.getTransactionReceipt(tx_address)
        return tx_receipt

    ''' These functions are accessed by non-ceo. a new microgrid
        contract client needs to be created for each meter on
        the network
    '''
    def generateWattHours(self, watt_hours):
        tx_address = self.contract.transact(self.tx_info).\
                generateWattHours(watt_hours)
        tx_receipt = self.web3.eth.getTransactionReceipt(tx_address)
        return tx_receipt

    def consumeWattHours(self, watt_hours):
        tx_address = self.contract.transact(self.tx_info).\
                consumeWattHours(watt_hours)
        tx_receipt = self.web3.eth.getTransactionReceipt(tx_address)
        return tx_receipt

