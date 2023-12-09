// Import necessary libraries and dependencies
const { expectEvent, BN } = require("@openzeppelin/test-helpers");
const HDWalletProvider = require("@truffle/hdwallet-provider");
const Web3 = require('web3');

// Import the DiaChain smart contract artifacts
const DiaChain = artifacts.require("DiaChain");

// Contract tests for DiaChain
contract('DiaChain', (accounts) => {

  // Before running the tests, set up initial variables and deploy DiaChain smart contract
  before(async () => {
    this.owner = accounts[0];

    // Constants for mining locations and enums for modes and statuses
    this.MINING_LOCATION = {
      South_Africa: "South_Africa",
      Australia: "Australia",
      Congo: "Congo",
      Namibia: "Namibia"
    };
    this.ModeEnums = {
      ISSUER: { val: "ISSUER", pos: 0 },
      PROVER: { val: "PROVER", pos: 1 },
      VERIFIER: { val: "VERIFIER", pos: 2 }
    };
    this.StatusEnums = {
      supplied: { val: "SUPPLIED", pos: 0 },
      deliver1: { val: "ROUGH_EXPORT", pos: 1 },
      trade1: { val: "ROUGH_TRADE", pos: 2 },
      deliver2: { val: "POLISHED_EXPORT", pos: 3 },
      trade2: { val: "POLISHED_TRADE", pos: 4 }
    };

    // Default entities and diamond batches for testing
    this.defaultEntities = {
      supplierA: { id: accounts[1], mode: this.ModeEnums.PROVER.val },
      supplierB: { id: accounts[2], mode: this.ModeEnums.PROVER.val },
      inspector: { id: accounts[3], mode: this.ModeEnums.ISSUER.val },
      distributorGlobal: { id: accounts[4], mode: this.ModeEnums.VERIFIER.val },
      distributorLocal: { id: accounts[5], mode: this.ModeEnums.VERIFIER.val },
      polisher: { id: accounts[6], mode: this.ModeEnums.ISSUER.val },
      jewelryRetailer: { id: accounts[7], mode: this.ModeEnums.VERIFIER.val }
    };
    this.defaultDiamondBatches = {
      0: { mining_location: this.MINING_LOCATION.South_Africa, supplier: this.defaultEntities.supplierA.id },
      // ... (similar entries for other diamond batches)
    };

    // Deploy the DiaChain smart contract
    this.diaChainInstance = await DiaChain.deployed();
  });

  // Test case1: Add entities successfully
  it('should add entities successfully', async () => {
    for (const entity in this.defaultEntities) {
      const { id, mode } = this.defaultEntities[entity];
      const result = await this.diaChainInstance.addEntity(
        id,
        mode,
        { from: this.owner }
      );
      expectEvent(result.receipt, "AddEntity", {
        entityId: id,
        entityMode: mode
      });
      const retrievedEntity = await this.diaChainInstance.entities.call(id);
      assert.equal(id, retrievedEntity.id, "mismatched ids");
      assert.equal(this.ModeEnums[mode].pos, retrievedEntity.mode.toString(), "mismatched modes");
    }
  });

  // Test case2: Add diamond batches successfully
  it('should add diamond batches successfully', async () => {
    for (let i = 0; i < Object.keys(this.defaultDiamondBatches).length; i++) {
      const { mining_location, supplier } = this.defaultDiamondBatches[i];
      const result = await this.diaChainInstance.addDiamondBatch(
        mining_location, supplier,
        { from: this.owner }
      );
      expectEvent(result.receipt, "AddDiamondBatch", {
        diamondBatchId: String(i),
        supplier: supplier
      });
      const retrievedDiamondBatch = await this.diaChainInstance.diamondBatches.call(i);
      assert.equal(i, retrievedDiamondBatch.id);
      assert.equal(mining_location, retrievedDiamondBatch.mining_location);
      assert.equal(supplier, retrievedDiamondBatch.supplier);
      assert.equal(undefined, retrievedDiamondBatch.certificateIds);
    }
  });

  // Test case3: Sign a message and store it as a certificate from issuer to the prover successfully
  it('should sign a message and store as a certificate from issuer to the prover successfully', async () => {
    // Set mnemonic and provider URL for wallet
    const mnemonic = "YOUR_PRIVATE_KEY";
    const providerOrUrl = "http://127.0.0.1:8545";
    
    // Create a new HDWalletProvider
    const provider = new HDWalletProvider({
      mnemonic,
      providerOrUrl
    });
    this.web3 = new Web3(provider);

    // Get entities for signing a certificate
    const { inspector, supplierA } = this.defaultEntities;
    const diamondBatchId = 0;
    const message = `Inspector (${inspector.id}) certifies diamond batch #${diamondBatchId} for supplier (${supplierA.id}).`;
    
    // Sign the message using the web3 provider
    const signature = await this.web3.eth.sign(
      this.web3.utils.keccak256(message),
      inspector.id
    );

    // Issue a certificate and check the result
    const result = await this.diaChainInstance.issueCertificate(
      inspector.id,
      supplierA.id,
      this.StatusEnums.supplied.val,
      diamondBatchId,
      signature,
      { from: this.owner }
    );

    expectEvent(result.receipt, "IssueCertificate", {
      issuer: inspector.id,
      prover: supplierA.id,
      certificateId: new BN(0)
    });

    // Check the retrieved certificate details
    const retrievedCertificate = await this.diaChainInstance.certificates.call(0);
    assert.equal(retrievedCertificate.id, 0);
    assert.equal(retrievedCertificate.issuer["id"], inspector.id);
    assert.equal(retrievedCertificate.prover["id"], supplierA.id);
    assert.equal(retrievedCertificate.signature, signature);
    assert.equal(retrievedCertificate.status, this.StatusEnums.supplied.pos.toString());
  });

  // Test case4: Verify that the certificate signature matches the issuer
  it('should verify that the certificate signature matches the issuer', async () => {
    const { inspector, supplierA } = this.defaultEntities;
    const diamondBatchId = 0;
    const message = `Inspector (${inspector.id}) certifies diamond batch #${diamondBatchId} for supplier (${supplierA.id}).`;

    // Retrieve certificate details
    const certificate = await this.diaChainInstance.certificates.call(0);

    // Check if the signature matches the issuer
    const signerMatches = await this.diaChainInstance.isMatchingSignature(
      this.web3.utils.keccak256(message),
      certificate.id,
      inspector.id,
      { from: this.owner }
    );

    assert.equal(signerMatches, true);
  });
});
