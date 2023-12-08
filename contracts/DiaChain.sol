// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

// Library for handling cryptographic operations related to signatures
library CryptoSuite {
    // Function to split a signature into its components
    function splitsSignature(
        bytes memory sig
    ) internal pure returns (uint8 v, bytes32 r, bytes32 s) {
        // Ensure the signature length is 65 bytes
        require(sig.length == 65);

        assembly {
            // Extract the first 32 bytes (r)
            r := mload(add(sig, 32))

            // Extract the next 32 bytes (s)
            s := mload(add(sig, 64))

            // Extract the last 32 bytes (v)
            v := byte(0, mload(add(sig, 96)))
        }

        return (v, r, s);
    }

    // Function to recover the signer's address from a message and signature
    function recoverSigner(
        bytes32 message,
        bytes memory sig
    ) internal pure returns (address) {
        // Split the signature into its components
        (uint8 v, bytes32 r, bytes32 s) = splitsSignature(sig);
        
        // Prefix the message and hash it
        bytes memory prefix = "\x19Ethereum Signed Message:\n32";
        bytes32 prefixedHash = keccak256(abi.encodePacked(prefix, message));

        // Recover the signer's address using ecrecover
        return ecrecover(prefixedHash, v, r, s);
    }
}

// Main contract for managing the DiaChain
contract DiaChain {
    // Enum defining the different modes an entity can have
    enum Mode {
        ISSUER,
        PROVER,
        VERIFIER
    }

    // Struct representing an entity in the system
    struct Entity {
        address id;
        Mode mode;
        uint[] certificateIds;
    }

    // Enum defining the different statuses a certificate can have
    enum Status {
        SUPPLIED,
        ROUGH_EXPORT,
        ROUGH_TRADE,
        POLISHED_EXPORT,
        POLISHED_TRADE
    }

    // Struct representing a certificate
    struct Certificate {
        uint id;
        Entity issuer;
        Entity prover;
        bytes signature;
        Status status;
    }

    // Struct representing a batch of diamonds
    struct DiamondBatch {
        uint id;
        string mining_location;
        address supplier;
        uint[] certificateIds;
    }

    // Constants
    uint public constant MAX_CERTIFICATIONS = 2;

    // Arrays to store certificate and batch IDs
    uint[] public certificateIds;
    uint[] public diamondBatchIds;

    // Maps batch IDs to DiamondBatch structs
    mapping(uint => DiamondBatch) public diamondBatches;

    // Maps certificate IDs to Certificate structs
    mapping(uint => Certificate) public certificates;

    // Maps entity addresses to Entity structs
    mapping(address => Entity) public entities;

    // Events for logging
    event AddEntity(address entityId, string entityMode);
    event AddDiamondBatch(uint diamondBatchId, address indexed supplier);
    event IssueCertificate(
        address indexed issuer,
        address indexed prover,
        uint certificateId
    );

    // Function to add a new entity to the system
    function addEntity(address _id, string memory _mode) public {
        Mode mode = unmarshalMode(_mode);
        uint[] memory _certificateIds = new uint[](MAX_CERTIFICATIONS);
        Entity memory entity = Entity(_id, mode, _certificateIds);
        entities[_id] = entity;

        emit AddEntity(entity.id, _mode);
    }

    // Function to convert a string mode to the corresponding enum value
    function unmarshalMode(
        string memory _mode
    ) private pure returns (Mode mode) {
        bytes32 encodedMode = keccak256(abi.encodePacked(_mode));
        bytes32 encodedMode0 = keccak256(abi.encodePacked("ISSUER"));
        bytes32 encodedMode1 = keccak256(abi.encodePacked("PROVER"));
        bytes32 encodedMode2 = keccak256(abi.encodePacked("VERIFIER"));

        if (encodedMode == encodedMode0) {
            return Mode.ISSUER;
        } else if (encodedMode == encodedMode1) {
            return Mode.PROVER;
        } else if (encodedMode == encodedMode2) {
            return Mode.VERIFIER;
        }

        revert("received invalid entity mode");
    }

    // Function to add a new diamond batch to the system
    function addDiamondBatch(
        string memory mining_location,
        address supplier
    ) public returns (uint) {
        uint[] memory _certificateIds = new uint[](MAX_CERTIFICATIONS);
        uint id = diamondBatchIds.length;
        DiamondBatch memory batch = DiamondBatch(
            id,
            mining_location,
            supplier,
            _certificateIds
        );

        diamondBatches[id] = batch;
        diamondBatchIds.push(id);

        emit AddDiamondBatch(batch.id, batch.supplier);
        return id;
    }

    // Function to issue a new certificate
    function issueCertificate(
        address _issuer,
        address _prover,
        string memory _status,
        uint diamondBatchId,
        bytes memory signature
    ) public returns (uint) {
        // Check that the issuer is valid
        Entity memory issuer = entities[_issuer];
        require(issuer.mode == Mode.ISSUER);

        // Check that the prover is valid
        Entity memory prover = entities[_prover];
        require(prover.mode == Mode.PROVER);

        // Convert status string to Status enum
        Status status = unmarshalStatus(_status);

        // Create a new certificate
        uint id = certificateIds.length;
        Certificate memory certificate = Certificate(
            id,
            issuer,
            prover,
            signature,
            status
        );

        // Add the certificate to the arrays and mappings
        certificateIds.push(certificateIds.length);
        certificates[certificateIds.length - 1] = certificate;

        // Emit an event for the issued certificate
        emit IssueCertificate(_issuer, _prover, certificateIds.length - 1);

        return certificateIds.length - 1;
    }

    // Function to convert a status string to the corresponding enum value
    function unmarshalStatus(
        string memory _status
    ) private pure returns (Status status) {
        bytes32 encodedStatus = keccak256(abi.encodePacked(_status));
        bytes32 encodedStatus0 = keccak256(abi.encodePacked("SUPPLIED"));
        bytes32 encodedStatus1 = keccak256(abi.encodePacked("ROUGH_EXPORT"));
        bytes32 encodedStatus2 = keccak256(abi.encodePacked("ROUGH_TRADE"));
        bytes32 encodedStatus3 = keccak256(abi.encodePacked("POLISHED_EXPORT"));
        bytes32 encodedStatus4 = keccak256(abi.encodePacked("POLISHED_TRADE"));

        if (encodedStatus == encodedStatus0) {
            return Status.SUPPLIED;
        } else if (encodedStatus == encodedStatus1) {
            return Status.ROUGH_EXPORT;
        } else if (encodedStatus == encodedStatus2) {
            return Status.ROUGH_TRADE;
        } else if (encodedStatus == encodedStatus3) {
            return Status.POLISHED_EXPORT;
        } else if (encodedStatus == encodedStatus4) {
            return Status.POLISHED_TRADE;
        }

        revert("received invalid certification status");
    }

    // Function to check if the signature matches the issuer
    function isMatchingSignature(
        bytes32 message,
        uint id,
        address issuer
    ) public view returns (bool) {
        Certificate memory cert = certificates[id];
        require(cert.issuer.id == issuer);

        // Recover the signer's address and check if it matches the issuer
        address recoveredSigner = CryptoSuite.recoverSigner(
            message,
            cert.signature
        );

        return recoveredSigner == cert.issuer.id;
    }
}
