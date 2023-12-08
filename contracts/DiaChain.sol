pragma solidity >=0.7.0 <0.9.0;

library CryptoSuite {
    function splitsSignature(
        bytes memory sig
    ) internal pure returns (uint8 v, bytes32 r, bytes32 s) {
        require(sig.length == 65);

        assembly {
            // first 32bytes
            r := mload(add(sig, 32))

            // next 32bytes
            s := mload(add(sig, 64))

            // last 32bytes
            v := byte(0, mload(add(sig, 96)))
        }

        return (v, r, s);
    }

    function recoverSigner(
        bytes32 message,
        bytes memory sig
    ) internal pure returns (address) {
        (uint8 v, bytes32 r, bytes32 s) = splitsSignature(sig);
        bytes memory prefix = "\x19Ethereum Signed Message:\n32";
        bytes32 prefixedHash = keccak256(abi.encodePacked(prefix, message));

        return ecrecover(prefixedHash, v, r, s);
    }
}

contract DiaChain {
    enum Mode {
        ISSUER,
        PROVER,
        VERIFIER
    }
    struct Entity {
        address id;
        Mode mode;
        uint[] certificateIds;
    }

    enum Status {
        SUPPLIED,
        ROUGH_EXPORT,
        ROUGH_TRADE,
        POLISHED_EXPORT,
        POLISHED_TRADE
    }

    struct Certificate {
        uint id;
        Entity issuer;
        Entity prover;
        bytes signature;
        Status status;
    }

    struct DiamondBatch {
        uint id;
        string mining_location;
        address supplier;
        uint[] certificateIds;
    }

    uint public constant MAX_CERTIFICATIONS = 2;

    uint[] public certificateIds;
    uint[] public diamondBatchIds;

    mapping(uint => DiamondBatch) public diamondBatches;
    mapping(uint => Certificate) public certificates;
    mapping(address => Entity) public entities;

    event AddEntity(address entityId, string entityMode);
    event AddDiamondBatch(uint diamondBatchId, address indexed supplier);
    event IssueCertificate(
        address indexed issuer,
        address indexed prover,
        uint certificateId
    );

    function addEntity(address _id, string memory _mode) public {
        Mode mode = unmarshalMode(_mode);
        uint[] memory _certificateIds = new uint[](MAX_CERTIFICATIONS);
        Entity memory entity = Entity(_id, mode, _certificateIds);
        entities[_id] = entity;

        emit AddEntity(entity.id, _mode);
    }

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

    function issueCertificate(
        address _issuer,
        address _prover,
        string memory _status,
        uint diamondBatchId,
        bytes memory signature
    ) public returns (uint) {
        Entity memory issuer = entities[_issuer];
        require(issuer.mode == Mode.ISSUER);

        Entity memory prover = entities[_prover];
        require(prover.mode == Mode.PROVER);

        Status status = unmarshalStatus(_status);

        uint id = certificateIds.length;
        Certificate memory certificate = Certificate(
            id,
            issuer,
            prover,
            signature,
            status
        );

        certificateIds.push(certificateIds.length);
        certificates[certificateIds.length - 1] = certificate;

        emit IssueCertificate(_issuer, _prover, certificateIds.length - 1);

        return certificateIds.length - 1;
    }

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

    function isMatchingSignature(
        bytes32 message,
        uint id,
        address issuer
    ) public view returns (bool) {
        Certificate memory cert = certificates[id];
        require(cert.issuer.id == issuer);

        address recoveredSigner = CryptoSuite.recoverSigner(
            message,
            cert.signature
        );

        return recoveredSigner == cert.issuer.id;
    }
}
