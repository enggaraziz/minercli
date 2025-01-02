import vana
import os
import json

from eth_account import Account
from dataclasses import dataclass

from web3 import Web3
from web3.middleware import geth_poa_middleware

from constants import NETWORK


@dataclass
class ChainConfig:
    network: str
    chain_endpoint: str | None = None


def get_wallet():
    wallet = vana.Wallet()
    if vana_private_key := os.getenv("VANA_PRIVATE_KEY"):
        account = Account.from_key(vana_private_key)
        wallet._hotkey = account
    return wallet


# def get_chain_manager():
#     config = vana.Config()
#     config.chain = ChainConfig(network=NETWORK)
#     if NETWORK == "vana":  # TODO: make this work with Vana lib
#         config.chain = ChainConfig(network="https://rpc.vana.org")
#     chain_manager = vana.ChainManager(config=config)
#     chain_manager.web3 = Web3(Web3.HTTPProvider("https://rpc.vana.org"))
#     chain_manager.web3.middleware_onion.inject(geth_poa_middleware, layer=0)
#     return vana.ChainManager()

def get_chain_manager():
    config = vana.Config()
    if NETWORK == "vana":
        config.chain = {"network": "vana", "chain_endpoint": "https://rpc.vana.org"}
    else:
        config.chain = {"network": NETWORK}
    
    print("Config.chain:", json.dumps(config.chain, indent=2))
    
    chain_manager = vana.ChainManager(config=config)
    chain_manager.web3 = Web3(Web3.HTTPProvider("https://rpc.vana.org"))
    chain_manager.web3.middleware_onion.inject(geth_poa_middleware, layer=0)
    return vana.ChainManager()
#     return chain_manager
