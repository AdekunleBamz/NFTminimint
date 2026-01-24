// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/**
 * @title NFTCore
 * @dev Base ERC721 implementation with core minting functionality
 * @author Adekunle Bamz
 * @notice This is the foundational contract for the NFTminimint platform
 * @dev Provides basic NFT minting, burning, and token management
 */
abstract contract NFTCore is ERC721, ERC721URIStorage, ERC721Burnable, ReentrancyGuard {
    
    /// @dev Counter for generating unique token IDs
    uint256 internal _tokenIdCounter;
    
    /// @dev Base URI for token metadata
    string internal _baseTokenURI;
    
    /// @dev Mapping from token ID to creator address
    mapping(uint256 => address) internal _creators;
    
    /// @dev Mapping from token ID to creation timestamp
    mapping(uint256 => uint256) internal _mintTimestamps;

    /**
     * @dev Emitted when a new NFT is minted
     * @param to Recipient address
     * @param tokenId The minted token ID
     * @param creator The original creator/minter
     * @param timestamp Block timestamp of minting
     */
    event TokenMinted(
        address indexed to,
        uint256 indexed tokenId,
        address indexed creator,
        uint256 timestamp
    );

    /**
     * @dev Emitted when a token is burned
     * @param tokenId The burned token ID
     * @param burner Address that burned the token
     */
    event TokenBurned(uint256 indexed tokenId, address indexed burner);

    /**
     * @dev Emitted when base URI is updated
     * @param oldURI Previous base URI
     * @param newURI New base URI
     */
    event BaseURIUpdated(string oldURI, string newURI);

    /**
     * @notice Get the creator of a specific token
     * @param tokenId The token ID to query
     * @return The creator's address
     */
    function creatorOf(uint256 tokenId) public view virtual returns (address) {
        require(_ownerOf(tokenId) != address(0), "NFTCore: Token does not exist");
        return _creators[tokenId];
    }

    /**
     * @notice Get the mint timestamp of a token
     * @param tokenId The token ID to query
     * @return The timestamp when the token was minted
     */
    function mintTimestamp(uint256 tokenId) public view virtual returns (uint256) {
        require(_ownerOf(tokenId) != address(0), "NFTCore: Token does not exist");
        return _mintTimestamps[tokenId];
    }

    /**
     * @notice Get the current token ID counter
     * @return Current counter value (next token ID)
     */
    function currentTokenId() public view virtual returns (uint256) {
        return _tokenIdCounter;
    }

    /**
     * @notice Get the total number of tokens minted
     * @return Total supply of tokens
     */
    function totalSupply() public view virtual returns (uint256) {
        return _tokenIdCounter;
    }

    /**
     * @dev Internal function to mint a new token
     * @param to Recipient address
     * @param uri Token metadata URI
     * @return tokenId The newly minted token ID
     */
    function _mintToken(address to, string memory uri) internal virtual returns (uint256) {
        require(to != address(0), "NFTCore: Cannot mint to zero address");
        
        uint256 tokenId = _tokenIdCounter;
        _tokenIdCounter++;
        
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, uri);
        
        _creators[tokenId] = msg.sender;
        _mintTimestamps[tokenId] = block.timestamp;
        
        emit TokenMinted(to, tokenId, msg.sender, block.timestamp);
        
        return tokenId;
    }

    /**
     * @dev Internal function to burn a token
     * @param tokenId Token ID to burn
     */
    function _burnToken(uint256 tokenId) internal virtual {
        address owner = _ownerOf(tokenId);
        require(owner != address(0), "NFTCore: Token does not exist");
        
        super._burn(tokenId);
        
        delete _creators[tokenId];
        delete _mintTimestamps[tokenId];
        
        emit TokenBurned(tokenId, msg.sender);
    }

    /**
     * @dev Set the base URI for all tokens
     * @param baseURI New base URI
     */
    function _setBaseURI(string memory baseURI) internal virtual {
        string memory oldURI = _baseTokenURI;
        _baseTokenURI = baseURI;
        emit BaseURIUpdated(oldURI, baseURI);
    }

    /**
     * @dev Override base URI function
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    /**
     * @notice Check if a token exists
     * @param tokenId Token ID to check
     * @return True if token exists
     */
    function exists(uint256 tokenId) public view virtual returns (bool) {
        return _ownerOf(tokenId) != address(0);
    }

    /**
     * @dev Get all tokens owned by an address (gas intensive for large collections)
     * @param owner Address to query
     * @return Array of token IDs owned by the address
     */
    function tokensOfOwner(address owner) public view virtual returns (uint256[] memory) {
        uint256 balance = balanceOf(owner);
        uint256[] memory tokens = new uint256[](balance);
        uint256 index = 0;
        
        for (uint256 i = 0; i < _tokenIdCounter && index < balance; i++) {
            if (_ownerOf(i) == owner) {
                tokens[index] = i;
                index++;
            }
        }
        
        return tokens;
    }

    // ============ Required Overrides ============

    function _burn(uint256 tokenId) internal virtual override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId) public view virtual override(ERC721, ERC721URIStorage) returns (string memory) {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC721URIStorage) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
