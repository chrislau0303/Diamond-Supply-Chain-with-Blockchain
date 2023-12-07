const {expectEvent, BN} = require("@openzeppelin/test-helpers");
const HDWalletProvider = require("@truffle/hdwallet-provider");
const Web3 = require('web3');

const DiaChain = artifacts.require("/Users/dennislaw/Documents/supplychain-project/contracts/DiaChain");

contract('DiaChain', (accounts) => {

  before(async() =>{
    this.owner = accounts[0];

    this.MINING_LOCATION = {
      South_Africa: "South_Africa",
      Australia: "Australia",
      Congo: "Congo",
      Namibia: "Namibia"
    };
    //enums
    this.ModeEnums = {
      ISSUER: {val: "ISSUER",pos:0},
      PROVER: {val: "PROVER",pos:1},
      VERIFIER: {val: "VERIFIER",pos:2}
    };
    this.StatusEnums = { // MINED, ROUGH_TRADE, POLISHED, POLISHED_TRADE, JEWELLER
      mined: {val: "MINED",pos:0},
      trade1: {val: "ROUGH_TRADE",pos:1},
      polished: {val: "POLISHED",pos:2},
      trade2: {val: "POLISHED_TRADE",pos:3},
      jeweller: {val: "JEWELLER",pos:4}
    };

    this.defaultEntities = {
      manufacturerA: {id: accounts[1], mode: this.ModeEnums.PROVER.val},
      manufacturerB: {id: accounts[2], mode: this.ModeEnums.PROVER.val},
      inspector: {id: accounts[3], mode: this.ModeEnums.ISSUER.val},
      distributorGlobal: {id: accounts[4], mode: this.ModeEnums.VERIFIER.val},
      distributorLocal: {id: accounts[5], mode: this.ModeEnums.VERIFIER.val},
      polisher: {id: accounts[6], mode: this.ModeEnums.ISSUER.val},
      customer: {id: accounts[7], mode: this.ModeEnums.PROVER.val},
      borderAgent: {id: accounts[8], mode: this.ModeEnums.VERIFIER.val}

    };
    this.defaultVaccineBatches = {
      0: {brand: this.MINING_LOCATION.South_Africa, manufacturer: this.defaultEntities.manufacturerA.id},
      1: {brand: this.MINING_LOCATION.Australia, manufacturer: this.defaultEntities.manufacturerA.id},
      2: {brand: this.MINING_LOCATION.Congo, manufacturer: this.defaultEntities.manufacturerB.id},
      3: {brand: this.MINING_LOCATION.Namibia, manufacturer: this.defaultEntities.manufacturerB.id},
      4: {brand: this.MINING_LOCATION.South_Africa, manufacturer: this.defaultEntities.manufacturerB.id},
      5: {brand: this.MINING_LOCATION.South_Africa, manufacturer: this.defaultEntities.manufacturerA.id},
      6: {brand: this.MINING_LOCATION.Australia, manufacturer: this.defaultEntities.manufacturerA.id},
      7: {brand: this.MINING_LOCATION.Australia, manufacturer: this.defaultEntities.manufacturerB.id},
      8: {brand: this.MINING_LOCATION.Namibia, manufacturer: this.defaultEntities.manufacturerB.id},
      9: {brand: this.MINING_LOCATION.Congo, manufacturer: this.defaultEntities.manufacturerA.id},
    };

    this.diaChainInstance = await DiaChain.deployed();
  });
  it('should add entities successfully', async () => {
    for(const entity in this.defaultEntities){
      const {id, mode} = this.defaultEntities[entity];
      const result = await this.diaChainInstance.addEntity(
        id,
        mode,
        {from: this.owner}
      );
      // console.log(result);
      expectEvent(result.receipt, "AddEntity", {
        entityId: id,
        entityMode: mode

      });
      const retrievedEntity = await this.diaChainInstance.entities.call(id);
      assert.equal(id, retrievedEntity.id, "mismatched ids");
      assert.equal(this.ModeEnums[mode].pos, retrievedEntity.mode.toString(), "mismatched modes");

    }
  });
  it('should add vaccine batched successfully', async () => {
    for(let i=0; i< Object.keys(this.defaultVaccineBatches).length; i++){
      const {brand, manufacturer} = this.defaultVaccineBatches[i];
      const result = await this.diaChainInstance.addVaccineBatch(
        brand, manufacturer,
        {from: this.owner}
      );
      // console.log(result);
      expectEvent(result.receipt, "AddVaccineBatch", {
        vaccineBatchId: String(i),
        manufacturer: manufacturer

      });
      const retrievedVaccineBatch = await this.diaChainInstance.vaccineBatches.call(i);
      assert.equal(i, retrievedVaccineBatch.id);
      assert.equal(brand, retrievedVaccineBatch.brand);
      assert.equal(manufacturer, retrievedVaccineBatch.manufacturer);
      assert.equal(undefined, retrievedVaccineBatch.certificateIds);
     
    }
  });

  it('should sign a message and store as a certificate from issuer to the prover successfully', async () => {
      const mnemonic = "kiss display south atom basket tiger ethics trial expect hub clarify barrel";
      const providerOrUrl = "http://127.0.0.1:8545";
      const provider = new HDWalletProvider({
        mnemonic,
        providerOrUrl
      });
      console.log("Provider URL:", providerOrUrl);
      this.web3 = new Web3(provider);      

      const {inspector, manufacturerA} = this.defaultEntities;
      const vaccineBatchId = 0;
      const message = `Inspector (${inspector.id}) certifies vaccine batch #${vaccineBatchId} for Manufacturer (${manufacturerA.id}).`;
      const signature = await this.web3.eth.sign(
        this.web3.utils.keccak256(message),
        inspector.id
      );

      const result = await this.diaChainInstance.issueCertificate(
        inspector.id,
        manufacturerA.id,
        this.StatusEnums.mined.val,
        vaccineBatchId,
        signature,
        {from: this.owner}
      );

      expectEvent(result.receipt, "IssueCertificate", {
        issuer: inspector.id,
        prover: manufacturerA.id,
        certificateId: new BN(0)
      });
  });
});
