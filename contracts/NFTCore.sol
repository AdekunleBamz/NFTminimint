// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/**
 * @title NFTCore
 * @dev Base ERC721 contract - DEPLOY FIRST
 * @author Adekunle Bamz
 * @notice Core NFT functionality with minting and burning
 * 
 * DEPLOYMENT ORDER: 1st (No dependencies)
 * CONSTRUCTOR ARGS: 2
 *   - name_ (string): Collection name
 *   - symbol_ (string): Collection symbol
 */
contract NFTCore is ERC721, ERC721URIStorage, ERC721Burnable, Ownable, ReentrancyGuard {
    
    /// @dev Token ID counter
    uint256 private _tokenIdCounter;
    
    /// @dev Base URI for metadata
    string private _baseTokenURI;
    
    /// @dev Authorized minter addresses (other contracts)
    mapping(address => bool) public authorizedMinters;
    
    /// @dev Mapping from token ID to creator
    mapping(uint256 => address) public creators;
    
    /// @dev Mapping from token ID to mint timestamp
    mapping(uint256 => uint256) public mintTimestamps;
    
    /// @dev Total tokens burned
    uint256 private _burnedCount;

    /// @dev Emitted when token is minted
    event TokenMinted(address indexed to, uint256 indexed tokenId, address indexed minter);
    
    /// @dev Emitted when minter is authorized/revoked
    event MinterUpdated(address indexed minter, bool authorized);
    
    /// @dev Emitted when base URI changes
    event BaseURIUpdated(string newBaseURI);
    
    /// @dev Emitted when token URI is updated
    event TokenURIUpdated(uint256 indexed tokenId, string newURI);
    
    /// @dev Emitted when token is burned
    event TokenBurned(uint256 indexed tokenId, address indexed burner);

    /**
     * @dev Constructor
     * @param name_ Collection name
     * @param symbol_ Collection symbol
     */
    constructor(
        string memory name_,
        string memory symbol_
    ) ERC721(name_, symbol_) Ownable(msg.sender) {}

    /**
     * @dev Modifier for authorized minters
     */
    modifier onlyMinter() {
        require(
            authorizedMinters[msg.sender] || msg.sender == owner(),
            "NFTCore: Not authorized minter"
        );
        _;
    }

    // ============ MINTER MANAGEMENT ============

    /**
     * @notice Authorize a minter (another contract or address)
     * @param minter Address to authorize
     */
    function authorizeMinter(address minter) external onlyOwner {
        require(minter != address(0), "NFTCore: Zero address");
        authorizedMinters[minter] = true;
        emit MinterUpdated(minter, true);
    }

    /**
     * @notice Revoke minter authorization
     * @param minter Address to revoke
     */
    function revokeMinter(address minter) external onlyOwner {
        authorizedMinters[minter] = false;
        emit MinterUpdated(minter, false);
    }

    // ============ MINTING ============

    /**
     * @notice Mint a new token
     * @param to Recipient address
     * @param uri Token metadata URI
     * @return tokenId The minted token ID
     */
    function mint(address to, string memory uri) external onlyMinter nonReentrant returns (uint256) {
        require(to != address(0), "NFTCore: Zero address");
        
        uint256 tokenId = _tokenIdCounter;
        _tokenIdCounter++;
        
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, uri);
        
        creators[tokenId] = msg.sender;
        mintTimestamps[tokenId] = block.timestamp;
        
        emit TokenMinted(to, tokenId, msg.sender);
        return tokenId;
    }

    /**
     * @notice Batch mint tokens
     * @param to Recipient address
     * @param uris Array of metadata URIs
     * @return startTokenId First minted token ID
     */
    function batchMint(address to, string[] memory uris) external onlyMinter nonReentrant returns (uint256) {
        require(to != address(0), "NFTCore: Zero address");
        require(uris.length > 0, "NFTCore: Empty URIs");
        require(uris.length <= 50, "NFTCore: Max 50 per batch");
        
        uint256 startTokenId = _tokenIdCounter;
        
        for (uint256 i = 0; i < uris.length; i++) {
            uint256 tokenId = _tokenIdCounter;
            _tokenIdCounter++;
            
            _safeMint(to, tokenId);
            _setTokenURI(tokenId, uris[i]);
            
            creators[tokenId] = msg.sender;
            mintTimestamps[tokenId] = block.timestamp;
            
            emit TokenMinted(to, tokenId, msg.sender);
        }
        
        return startTokenId;
    }

    // ============ URI MANAGEMENT ============

    /**
     * @notice Set base URI
     * @param baseURI New base URI
     */
    function setBaseURI(string memory baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
        emit BaseURIUpdated(baseURI);
    }

    /**
     * @notice Update token URI
     * @param tokenId Token to update
     * @param uri New URI
     */
    function setTokenURI(uint256 tokenId, string memory uri) external onlyOwner {
        require(_ownerOf(tokenId) != address(0), "NFTCore: Token doesn't exist");
        _setTokenURI(tokenId, uri);
        emit TokenURIUpdated(tokenId, uri);
    }

    // ============ VIEW FUNCTIONS ============

    /**
     * @notice Get current token ID (total minted)
     */
    function currentTokenId() external view returns (uint256) {
        return _tokenIdCounter;
    }

    /**
     * @notice Get total supply
     */
    function totalSupply() external view returns (uint256) {
        return _tokenIdCounter;
    }

    /**
     * @notice Check if token exists
     */
    function exists(uint256 tokenId) external view returns (bool) {
        return _ownerOf(tokenId) != address(0);
    }

    /**
     * @notice Get token creation info
     * @param tokenId Token to query
     * @return creator Original minter
     * @return timestamp Mint timestamp
     */
    function getTokenCreationInfo(uint256 tokenId) external view returns (address creator, uint256 timestamp) {
        require(_ownerOf(tokenId) != address(0), "NFTCore: Token doesn't exist");
        return (creators[tokenId], mintTimestamps[tokenId]);
    }

    /**
     * @notice Get tokens owned by address
     */
    function tokensOfOwner(address owner_) external view returns (uint256[] memory) {
        uint256 balance = balanceOf(owner_);
        uint256[] memory tokens = new uint256[](balance);
        uint256 index = 0;
        
        for (uint256 i = 0; i < _tokenIdCounter && index < balance; i++) {
            if (_ownerOf(i) == owner_) {
                tokens[index] = i;
                index++;
            }
        }
        return tokens;
    }

    // ============ OVERRIDES ============

    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }

    function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721URIStorage) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    /**
     * @notice Get total burned tokens
     */
    function totalBurned() external view returns (uint256) {
        return _burnedCount;
    }

    /**
     * @notice Get current circulating supply (minted - burned)
     */
    function circulatingSupply() external view returns (uint256) {
        return _tokenIdCounter - _burnedCount;
    }

    /**
     * @notice Get total minted tokens
     */
    function totalMinted() external view returns (uint256) {
        return _tokenIdCounter;
    }
}
