// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title IdentityVerification
 * @dev Decentralized identity management system for secure identity verification
 * @author Your Name
 */
contract IdentityVerification {
    
    // Structure to store identity information
    struct Identity {
        string name;
        string email;
        uint256 dateOfBirth; // timestamp
        string documentHash; // IPFS hash or document hash
        bool isVerified;
        address verifier; // who verified this identity
        uint256 verificationDate;
        bool exists;
    }
    
    // Mapping from user address to their identity
    mapping(address => Identity) private identities;
    
    // Mapping to track authorized verifiers
    mapping(address => bool) public authorizedVerifiers;
    
    // Contract owner
    address public owner;
    
    // Events
    event IdentityRegistered(address indexed user, string name, uint256 timestamp);
    event IdentityVerified(address indexed user, address indexed verifier, uint256 timestamp);
    event VerifierAuthorized(address indexed verifier, uint256 timestamp);
    event VerifierRevoked(address indexed verifier, uint256 timestamp);
    
    // Modifiers
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }
    
    modifier onlyVerifier() {
        require(authorizedVerifiers[msg.sender], "Only authorized verifiers can call this function");
        _;
    }
    
    modifier identityExists(address user) {
        require(identities[user].exists, "Identity does not exist");
        _;
    }
    
    constructor() {
        owner = msg.sender;
        // Owner is automatically an authorized verifier
        authorizedVerifiers[owner] = true;
    }
    
    /**
     * @dev Register a new identity on the blockchain
     * @param _name Full name of the user
     * @param _email Email address of the user
     * @param _dateOfBirth Date of birth as timestamp
     * @param _documentHash Hash of identity document (stored off-chain)
     */
    function registerIdentity(
        string memory _name,
        string memory _email,
        uint256 _dateOfBirth,
        string memory _documentHash
    ) external {
        require(!identities[msg.sender].exists, "Identity already exists for this address");
        require(bytes(_name).length > 0, "Name cannot be empty");
        require(bytes(_email).length > 0, "Email cannot be empty");
        require(_dateOfBirth > 0, "Invalid date of birth");
        require(bytes(_documentHash).length > 0, "Document hash cannot be empty");
        
        identities[msg.sender] = Identity({
            name: _name,
            email: _email,
            dateOfBirth: _dateOfBirth,
            documentHash: _documentHash,
            isVerified: false,
            verifier: address(0),
            verificationDate: 0,
            exists: true
        });
        
        emit IdentityRegistered(msg.sender, _name, block.timestamp);
    }
    
    /**
     * @dev Verify an identity (only authorized verifiers can call this)
     * @param _user Address of the user whose identity to verify
     */
    function verifyIdentity(address _user) external onlyVerifier identityExists(_user) {
        require(!identities[_user].isVerified, "Identity is already verified");
        
        identities[_user].isVerified = true;
        identities[_user].verifier = msg.sender;
        identities[_user].verificationDate = block.timestamp;
        
        emit IdentityVerified(_user, msg.sender, block.timestamp);
    }
    
    /**
     * @dev Get identity information (returns public information only)
     * @param _user Address of the user whose identity to retrieve
     * @return name User's name
     * @return isVerified Whether the identity is verified
     * @return verifier Address of the verifier (if verified)
     * @return verificationDate Date when identity was verified
     */
    function getIdentity(address _user) external view identityExists(_user) 
        returns (
            string memory name,
            bool isVerified,
            address verifier,
            uint256 verificationDate
        ) 
    {
        Identity memory identity = identities[_user];
        return (
            identity.name,
            identity.isVerified,
            identity.verifier,
            identity.verificationDate
        );
    }
    
    /**
     * @dev Get detailed identity information (only the owner of identity can access)
     * @return name User's name
     * @return email User's email
     * @return dateOfBirth User's date of birth
     * @return documentHash Hash of identity document
     * @return isVerified Whether the identity is verified
     * @return verifier Address of the verifier
     * @return verificationDate Date when identity was verified
     */
    function getMyIdentity() external view 
        returns (
            string memory name,
            string memory email,
            uint256 dateOfBirth,
            string memory documentHash,
            bool isVerified,
            address verifier,
            uint256 verificationDate
        )
    {
        require(identities[msg.sender].exists, "You don't have a registered identity");
        Identity memory identity = identities[msg.sender];
        
        return (
            identity.name,
            identity.email,
            identity.dateOfBirth,
            identity.documentHash,
            identity.isVerified,
            identity.verifier,
            identity.verificationDate
        );
    }
    
    /**
     * @dev Authorize a new verifier (only owner can call this)
     * @param _verifier Address of the new verifier to authorize
     */
    function authorizeVerifier(address _verifier) external onlyOwner {
        require(_verifier != address(0), "Invalid verifier address");
        require(!authorizedVerifiers[_verifier], "Verifier is already authorized");
        
        authorizedVerifiers[_verifier] = true;
        emit VerifierAuthorized(_verifier, block.timestamp);
    }
    
    /**
     * @dev Revoke verifier authorization (only owner can call this)
     * @param _verifier Address of the verifier to revoke
     */
    function revokeVerifier(address _verifier) external onlyOwner {
        require(_verifier != owner, "Cannot revoke owner's verifier status");
        require(authorizedVerifiers[_verifier], "Verifier is not authorized");
        
        authorizedVerifiers[_verifier] = false;
        emit VerifierRevoked(_verifier, block.timestamp);
    }
    
    /**
     * @dev Check if an identity is verified
     * @param _user Address of the user to check
     * @return bool Whether the identity is verified
     */
    function isIdentityVerified(address _user) external view returns (bool) {
        return identities[_user].exists && identities[_user].isVerified;
    }
    
    /**
     * @dev Check if an address has a registered identity
     * @param _user Address to check
     * @return bool Whether the identity exists
     */
    function hasIdentity(address _user) external view returns (bool) {
        return identities[_user].exists;
    }
}
