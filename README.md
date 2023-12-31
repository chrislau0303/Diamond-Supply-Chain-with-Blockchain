# Blockchain Supply Chain: Diamond
## 1 Goal
This project showcases the journey of Diamond on blockchain.

The diamond supply chain is the sequence of activities and processes to bring raw diamonds from supplier(mines) to polished diamonds in jewelry stores .

## 2 Requirements Gathering
### 2.1 Diamond Supply Chain
![](https://github.com/chrislau0303/Diamond-Supply-Chain-with-Blockchain/blob/main/assets/Diamond-Supply-Chain.png)

### 2.2 System Actors
1. **Supplier**
   1. supply raw diamonds
1. **Distributor**
   1. transports diamonds between locations
1. **Inspector**
   1. performs quality checks on raw diamonds
1. **Polisher**
   1. process raw diamonds into diamond products
1. **Jewelry Retailer**
   1. sells the diamond product

### 2.4 Why Blockchain?
1. **Tamper-Proof Provenance**
   1. does the label on the diamond’s accurately represent its contents?
   1. did the diamond come from an inspected batch?
1. **Credential Issuance & Verification**
   1. cryptographic signatures that are easily verified with on-chain identities
1. **Data Redundancy**
   1. the data can’t be lost even if a customer “misplaces” their device
   1. the data can’t be lost even if the product are damaged

## 3 System Design
### 3.1 Flow
1. Inspector issues certificate for batch to supplier
1. ***batch status updated to SUPPLIED***
1. Supplier presents certificate to Distributor
1. Distributor verifies each certificate
1. ***batch status updated to ROUGH\_EXPORT***
1. Distributor presents updated certificate to Polisher
1. Polisher verifies each batch certificate
1. ***batch status updated to ROUGH\_TRADE***
1. Polisher presents certificates to Distributor
1. Distributor verifies each certificate
1. ***batch status updated to POLISHED\_EXPORT***
1. Distributor presents updated certificate to Jeweler
1. Jeweler verifies certificates
1. ***batch status updated to POLISHED\_TRADE***
## <a name="_n7wsp7frcbz1"></a>3.2 User Classifications
![](https://github.com/chrislau0303/Diamond-Supply-Chain-with-Blockchain/blob/main/assets/User-Classification%20.png)
### 3.3 Use Cases
1. As an ***Issuer***, I can issue a signature representing a digital certificate for a supplier’s plant
1. As a ***Prover***, I can present a certificate/signature issued to me
1. As a ***Verifier***, I can validate the signature on the blockchain
### 3.4 High-level Diagram
#### 3.4.1 3-Tiered Architecture
![](https://github.com/chrislau0303/Diamond-Supply-Chain-with-Blockchain/blob/main/assets/3-Tiered%20Architecture.png)
#### 3.4.2 2-Tiered “dApp” Architecture
![](https://github.com/chrislau0303/Diamond-Supply-Chain-with-Blockchain/blob/main/assets/2-Tiered%20%22dApp%22%20Architecture.png)


Tools and Technologies

- Solidity (Ethereum Smart Contract Language)
- HDWalletProvider
- Ropsten test network ( use ropsten faucet to get ethers on ropsten network )
- Truffle
- Infura
- Web3JS

Prerequisites

- Nodejs v18.19.0 or above
- Truffle v5.11.5 (core: 5.11.5) (npm install -g truffle)
- Solidity v0.8.13
- Ganache v7.9.1(npm install -g ganache-cli)
- Web3.js v1.10.0
- Openzeppelin/test-helpers v0.5.16
- Truffle/hdwallet-provider v1.7.0

Setting up Ethereum Smart Contract:
```
git clone https://github.com/chrislau0303/Diamond-Supply-Chain-with-Blockchain.git
cd Diamond-Supply-Chain-with-Blockchain
```
Run the following command:
```
rm -rf build
truffle compile
```

Open another terminal and run the following command:
```
ganache-cli -m "your private key"
```

Back to the original terminal and run:

```
truffle migrate
```

After successfully deployment you will get response in bash terminal like below
```
Compiling your contracts...
===========================
> Everything is up to date, there is nothing to compile.
Starting migrations...
======================
> Network name:    'development'
> Network id:      1702033139965
> Block gas limit: 6721975 (0x6691b7)
1\_deploy\_contracts.js
=====================
Deploying 'DiaChain'
--------------------
> transaction hash:    0xb890b585de7eda75a845de9fd26f40cb8b121d2d794d4d5b6f425b9b7468692d
> Blocks: 0            Seconds: 0
> contract address:    0xA9CBc0E8c7A57eDb7A9d2A64f9c0805f1006b42a
> block number:        1
> block timestamp:     1702033240
> account:             0x2b781Bf67572222F867b58f0F084CF629fd3e6A8
> balance:             99.95497346
> gas used:            2251327 (0x225a3f)
> gas price:           20 gwei
> value sent:          0 ETH
> total cost:          0.04502654 ETH
> Saving artifacts
-------------------------------------
> Total cost:          0.04502654 ETH
Summary
=======
> Total deployments:   1
> Final cost:          0.04502654 ETH
```
You can test by running the following commands:
```
npm install
truffle test
```

Remark:

Remember to change the mnemonic in diachain.js on line 97 to your own private key

