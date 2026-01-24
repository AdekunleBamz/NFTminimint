// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./NFTCollection.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title NFTminimint
 * @dev A comprehensive NFT minting platform with advanced features
 * @author Adekunle Bamz
 * @notice Main contract integrating all NFT functionality - FREE MINTING, NO FEES!
 * 
 * Features:
 * - FREE minting (no fees required)
 * - Batch minting support
 * - Airdrop functionality
 * - Whitelist management
 * - Role-based access control
 * - EIP-2981 royalties
 * - Pausable operations
 * - Metadata management
 * - Collection configuration
 */
contract NFTminimint is NFTCollection, Ownable {
    
    /// @dev Version of the contract
    string public constant VERSION = "2.0.0";

    /**
     * @dev Emitted when NFT is minted
     * @param to Recipient address
     * @param tokenId Minted token ID
     * @param uri Token metadata URI
     */
    event NFTMinted(address indexed to, uint256 indexed tokenId, string uri);

    /**
     * @dev Emitted when batch mint occurs
     * @param to Recipient address
     * @param startTokenId First token ID
     * @param quantity Number of tokens minted
     */
    event BatchMinted(address indexed to, uint256 indexed startTokenId, uint256 quantity);

    /**
     * @dev Emitted when airdrop occurs
     * @param recipients Number of recipients
     * @param tokensPerRecipient Tokens per recipient
     */
    event Airdropped(uint256 recipients, uint256 tokensPerRecipient);

    /**
     * @dev Constructor initializes the NFT collection
     * @param name_ Collection name
     * @param symbol_ Collection symbol
     * @param maxSupply_ Maximum supply (0 for unlimited)
     */
    constructor(
        string memory name_,
        string memory symbol_,
        uint256 maxSupply_
    ) ERC721(name_, symbol_) Ownable(msg.sender) {
        // Setup roles
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ADMIN_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
        _grantRole(PAUSER_ROLE, msg.sender);
        
        // Set max supply if provided
        if (maxSupply_ > 0) {
            _setMaxSupply(maxSupply_);
        }
        
        // Open public minting by default (FREE MINTING!)
        _setPublicMintOpen(true);
    }

    // ============ PUBLIC MINTING (FREE!) ============

    /**
     * @notice Mint a new NFT for FREE
     * @dev No fees required! Mints an NFT to the caller
     * @param uri The metadata URI for the NFT
     * @return tokenId The minted token ID
     */
    function mint(string memory uri) 
        external 
        nonReentrant 
        canMint(msg.sender) 
        withinSupply(1) 
        returns (uint256) 
    {
        _incrementMintCount(msg.sender);
        uint256 tokenId = _mintToken(msg.sender, uri);
        emit NFTMinted(msg.sender, tokenId, uri);
        return tokenId;
    }

    /**
     * @notice Mint an NFT to a specific address for FREE
     * @dev No fees required! Caller must pass access checks
     * @param to Recipient address
     * @param uri The metadata URI for the NFT
     * @return tokenId The minted token ID
     */
    function mintTo(address to, string memory uri) 
        external 
        nonReentrant 
        canMint(to) 
        withinSupply(1) 
        returns (uint256) 
    {
        _incrementMintCount(to);
        uint256 tokenId = _mintToken(to, uri);
        emit NFTMinted(to, tokenId, uri);
        return tokenId;
    }

    /**
     * @notice Batch mint multiple NFTs for FREE
     * @dev Mints multiple NFTs to the caller
     * @param uris Array of metadata URIs
     * @return startTokenId The first minted token ID
     */
    function batchMint(string[] memory uris) 
        external 
        nonReentrant 
        canMint(msg.sender) 
        withinSupply(uris.length) 
        returns (uint256) 
    {
        require(uris.length > 0, "NFTminimint: Empty URIs array");
        require(uris.length <= 50, "NFTminimint: Max 50 per batch");
        
        // Check mint limit
        if (maxMintsPerWallet > 0) {
            require(
                _mintsPerWallet[msg.sender] + uris.length <= maxMintsPerWallet,
                "NFTminimint: Would exceed wallet limit"
            );
        }
        
        uint256 startTokenId = _tokenIdCounter;
        
        for (uint256 i = 0; i < uris.length; i++) {
            _mintToken(msg.sender, uris[i]);
        }
        
        _incrementMintCountBy(msg.sender, uris.length);
        emit BatchMinted(msg.sender, startTokenId, uris.length);
        
        return startTokenId;
    }

    // ============ ADMIN FUNCTIONS ============

    /**
     * @notice Airdrop NFTs to multiple addresses
     * @dev Only admin can airdrop
     * @param recipients Array of recipient addresses
     * @param uri Metadata URI for all airdropped tokens
     */
    function airdrop(address[] memory recipients, string memory uri) 
        external 
        onlyRole(ADMIN_ROLE) 
        withinSupply(recipients.length) 
    {
        require(recipients.length > 0, "NFTminimint: Empty recipients");
        require(recipients.length <= 100, "NFTminimint: Max 100 per airdrop");
        
        for (uint256 i = 0; i < recipients.length; i++) {
            _mintToken(recipients[i], uri);
        }
        
        emit Airdropped(recipients.length, 1);
    }

    /**
     * @notice Airdrop multiple NFTs per address
     * @dev Only admin can airdrop
     * @param recipients Array of recipient addresses
     * @param uris 2D array of URIs per recipient
     */
    function batchAirdrop(address[] memory recipients, string[][] memory uris) 
        external 
        onlyRole(ADMIN_ROLE) 
    {
        require(recipients.length == uris.length, "NFTminimint: Length mismatch");
        require(recipients.length > 0, "NFTminimint: Empty recipients");
        
        uint256 totalTokens = 0;
        for (uint256 i = 0; i < uris.length; i++) {
            totalTokens += uris[i].length;
        }
        
        require(
            maxSupply == 0 || _tokenIdCounter + totalTokens <= maxSupply,
            "NFTminimint: Would exceed max supply"
        );
        
        for (uint256 i = 0; i < recipients.length; i++) {
            for (uint256 j = 0; j < uris[i].length; j++) {
                _mintToken(recipients[i], uris[i][j]);
            }
        }
        
        emit Airdropped(recipients.length, totalTokens / recipients.length);
    }

    // ============ ACCESS CONTROL MANAGEMENT ============

    /**
     * @notice Add address to whitelist
     * @param account Address to whitelist
     */
    function addToWhitelist(address account) external onlyRole(ADMIN_ROLE) {
        _addToWhitelist(account);
    }

    /**
     * @notice Batch add addresses to whitelist
     * @param accounts Array of addresses
     */
    function batchAddToWhitelist(address[] memory accounts) external onlyRole(ADMIN_ROLE) {
        _batchAddToWhitelist(accounts);
    }

    /**
     * @notice Remove address from whitelist
     * @param account Address to remove
     */
    function removeFromWhitelist(address account) external onlyRole(ADMIN_ROLE) {
        _removeFromWhitelist(account);
    }

    /**
     * @notice Batch remove addresses from whitelist
     * @param accounts Array of addresses
     */
    function batchRemoveFromWhitelist(address[] memory accounts) external onlyRole(ADMIN_ROLE) {
        _batchRemoveFromWhitelist(accounts);
    }

    /**
     * @notice Enable or disable whitelist
     * @param enabled Whether whitelist should be enabled
     */
    function setWhitelistEnabled(bool enabled) external onlyRole(ADMIN_ROLE) {
        _setWhitelistEnabled(enabled);
    }

    /**
     * @notice Set maximum mints per wallet
     * @param limit New limit (0 for unlimited)
     */
    function setMaxMintsPerWallet(uint256 limit) external onlyRole(ADMIN_ROLE) {
        _setMaxMintsPerWallet(limit);
    }

    /**
     * @notice Open or close public minting
     * @param open Whether public minting is open
     */
    function setPublicMintOpen(bool open) external onlyRole(ADMIN_ROLE) {
        _setPublicMintOpen(open);
    }

    // ============ COLLECTION MANAGEMENT ============

    /**
     * @notice Set max supply
     * @param supply New max supply (0 for unlimited)
     */
    function setMaxSupply(uint256 supply) external onlyRole(ADMIN_ROLE) {
        _setMaxSupply(supply);
    }

    /**
     * @notice Set collection information
     * @param name_ Collection name
     * @param description_ Collection description
     * @param image_ Collection image URI
     * @param externalLink_ External link
     */
    function setCollectionInfo(
        string memory name_,
        string memory description_,
        string memory image_,
        string memory externalLink_
    ) external onlyRole(ADMIN_ROLE) {
        _setCollectionInfo(name_, description_, image_, externalLink_);
    }

    /**
     * @notice Set contract URI (for OpenSea)
     * @param uri Contract metadata URI
     */
    function setContractURI(string memory uri) external onlyRole(ADMIN_ROLE) {
        _setContractURI(uri);
    }

    /**
     * @notice Set base URI for all tokens
     * @param baseURI New base URI
     */
    function setBaseURI(string memory baseURI) external onlyRole(ADMIN_ROLE) {
        _setBaseURI(baseURI);
    }

    // ============ METADATA MANAGEMENT ============

    /**
     * @notice Update a token's URI
     * @param tokenId Token to update
     * @param uri New metadata URI
     */
    function updateTokenURI(uint256 tokenId, string memory uri) external onlyRole(ADMIN_ROLE) {
        _updateTokenURI(tokenId, uri);
    }

    /**
     * @notice Set a token attribute
     * @param tokenId Token ID
     * @param key Attribute key
     * @param value Attribute value
     */
    function setTokenAttribute(uint256 tokenId, string memory key, string memory value) 
        external 
        onlyRole(ADMIN_ROLE) 
    {
        _setTokenAttribute(tokenId, key, value);
    }

    /**
     * @notice Freeze a token's metadata permanently
     * @param tokenId Token to freeze
     */
    function freezeTokenMetadata(uint256 tokenId) external onlyRole(ADMIN_ROLE) {
        _freezeTokenMetadata(tokenId);
    }

    /**
     * @notice Freeze all metadata permanently
     */
    function freezeAllMetadata() external onlyRole(ADMIN_ROLE) {
        _freezeMetadata();
    }

    // ============ ROYALTY MANAGEMENT ============

    /**
     * @notice Set default royalty for all tokens
     * @param recipient Royalty recipient
     * @param bps Royalty in basis points (e.g., 250 = 2.5%)
     */
    function setDefaultRoyalty(address recipient, uint96 bps) external onlyRole(ADMIN_ROLE) {
        _setDefaultRoyalty(recipient, bps);
    }

    /**
     * @notice Set royalty for a specific token
     * @param tokenId Token ID
     * @param recipient Royalty recipient
     * @param bps Royalty in basis points
     */
    function setTokenRoyalty(uint256 tokenId, address recipient, uint96 bps) 
        external 
        onlyRole(ADMIN_ROLE) 
    {
        _setTokenRoyalty(tokenId, recipient, bps);
    }

    // ============ PAUSE FUNCTIONS ============

    /**
     * @notice Pause all minting
     */
    function pause() external onlyRole(PAUSER_ROLE) {
        _pause();
    }

    /**
     * @notice Unpause minting
     */
    function unpause() external onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    // ============ BURN FUNCTION ============

    /**
     * @notice Burn a token you own
     * @param tokenId Token to burn
     */
    function burn(uint256 tokenId) public virtual override {
        require(
            _isAuthorized(_ownerOf(tokenId), msg.sender, tokenId),
            "NFTminimint: Not authorized to burn"
        );
        _burnToken(tokenId);
    }

    // ============ VIEW FUNCTIONS ============

    /**
     * @notice Get full token info
     * @param tokenId Token to query
     * @return owner Token owner
     * @return uri Token URI
     * @return creator Original minter
     * @return mintTime Mint timestamp
     * @return metadataFrozenStatus Whether metadata is frozen
     */
    function getTokenInfo(uint256 tokenId) 
        external 
        view 
        returns (
            address owner,
            string memory uri,
            address creator,
            uint256 mintTime,
            bool metadataFrozenStatus
        ) 
    {
        require(exists(tokenId), "NFTminimint: Token does not exist");
        return (
            ownerOf(tokenId),
            tokenURI(tokenId),
            creatorOf(tokenId),
            mintTimestamp(tokenId),
            isTokenMetadataFrozen(tokenId)
        );
    }

    /**
     * @notice Check if address can currently mint
     * @param account Address to check
     * @return canMintStatus Whether address can mint
     * @return reason Reason if cannot mint
     */
    function canAddressMint(address account) 
        external 
        view 
        returns (bool canMintStatus, string memory reason) 
    {
        if (paused()) {
            return (false, "Minting is paused");
        }
        
        if (maxSupply > 0 && _tokenIdCounter >= maxSupply) {
            return (false, "Sold out");
        }
        
        if (maxMintsPerWallet > 0 && _mintsPerWallet[account] >= maxMintsPerWallet) {
            return (false, "Wallet limit reached");
        }
        
        if (hasRole(MINTER_ROLE, account) || hasRole(ADMIN_ROLE, account)) {
            return (true, "Has minter role");
        }
        
        if (whitelistEnabled) {
            if (_whitelist[account]) {
                return (true, "Whitelisted");
            }
            return (false, "Not whitelisted");
        }
        
        if (publicMintOpen) {
            return (true, "Public mint open");
        }
        
        return (false, "Public mint not open");
    }

    // ============ REQUIRED OVERRIDES ============

    function _burn(uint256 tokenId) internal virtual override(NFTCore) {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId) 
        public 
        view 
        virtual 
        override(NFTCore) 
        returns (string memory) 
    {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId) 
        public 
        view 
        virtual 
        override(NFTCollection) 
        returns (bool) 
    {
        return super.supportsInterface(interfaceId);
    }

    function owner() public view virtual override returns (address) {
        return Ownable.owner();
    }
}
