// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/**
 * @title NFTCoreV3
 * @dev Core ERC721 with batch transfers, token locking, and soul-bound options
 * @author Adekunle Bamz
 * @notice DEPLOY FIRST - Base NFT contract with V3 features
 * 
 * V3 NEW FEATURES:
 *   - Batch transfers (transfer multiple tokens in one tx)
 *   - Token locking (for staking integration)
 *   - Soul-bound tokens (non-transferable)
 *   - Burn functionality
 */
contract NFTCoreV3 is ERC721, ERC721URIStorage, ERC721Enumerable, Ownable, ReentrancyGuard {
    
    string public constant VERSION = "3.0.0";
    
    uint256 private _tokenIdCounter;
    
    /// @dev Authorized minter (NFTminimintV3)
    address public authorizedMinter;
    
    /// @dev Token creator tracking
    mapping(uint256 => address) public creators;
    
    /// @dev Mint timestamps
    mapping(uint256 => uint256) public mintTimestamps;
    
    /// @dev Locked tokens (cannot be transferred while locked)
    mapping(uint256 => bool) public lockedTokens;
    
    /// @dev Soul-bound tokens (permanently non-transferable)
    mapping(uint256 => bool) public soulBoundTokens;
    
    /// @dev Authorized lockers (staking contract, etc.)
    mapping(address => bool) public authorizedLockers;

    event TokenMinted(address indexed to, uint256 indexed tokenId, address indexed creator);
    event TokenBurned(uint256 indexed tokenId, address indexed owner);
    event TokenLocked(uint256 indexed tokenId, address indexed locker);
    event TokenUnlocked(uint256 indexed tokenId, address indexed unlocker);
    event TokenMadeSoulBound(uint256 indexed tokenId);
    event BatchTransfer(address indexed from, address indexed to, uint256[] tokenIds);
    event MinterAuthorized(address indexed minter);
    event LockerAuthorized(address indexed locker, bool status);

    error NotAuthorizedMinter();
    error NotAuthorizedLocker();
    error TokenIsLocked(uint256 tokenId);
    error TokenIsSoulBound(uint256 tokenId);
    error NotTokenOwner();
    error TokenNotLocked();
    error ArrayLengthMismatch();

    constructor() ERC721("NFTminimint", "MINT") Ownable(msg.sender) {}

    modifier onlyMinter() {
        if (msg.sender != authorizedMinter && msg.sender != owner()) revert NotAuthorizedMinter();
        _;
    }

    modifier onlyLocker() {
        if (!authorizedLockers[msg.sender] && msg.sender != owner()) revert NotAuthorizedLocker();
        _;
    }

    // ============ MINTING ============

    function mint(address to, string memory uri) external onlyMinter returns (uint256) {
        _tokenIdCounter++;
        uint256 tokenId = _tokenIdCounter;
        
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, uri);
        
        creators[tokenId] = to;
        mintTimestamps[tokenId] = block.timestamp;
        
        emit TokenMinted(to, tokenId, to);
        return tokenId;
    }

    function mintSoulBound(address to, string memory uri) external onlyMinter returns (uint256) {
        _tokenIdCounter++;
        uint256 tokenId = _tokenIdCounter;
        
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, uri);
        
        creators[tokenId] = to;
        mintTimestamps[tokenId] = block.timestamp;
        soulBoundTokens[tokenId] = true;
        
        emit TokenMinted(to, tokenId, to);
        emit TokenMadeSoulBound(tokenId);
        return tokenId;
    }

    function batchMint(address to, string[] memory uris) external onlyMinter returns (uint256) {
        require(uris.length > 0 && uris.length <= 50, "NFTCoreV3: Invalid batch size");
        
        uint256 startId = _tokenIdCounter + 1;
        
        for (uint256 i = 0; i < uris.length; i++) {
            _tokenIdCounter++;
            uint256 tokenId = _tokenIdCounter;
            
            _safeMint(to, tokenId);
            _setTokenURI(tokenId, uris[i]);
            
            creators[tokenId] = to;
            mintTimestamps[tokenId] = block.timestamp;
            
            emit TokenMinted(to, tokenId, to);
        }
        
        return startId;
    }

    // ============ BATCH TRANSFERS ============

    function batchTransfer(address to, uint256[] calldata tokenIds) external nonReentrant {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            require(ownerOf(tokenIds[i]) == msg.sender, "NFTCoreV3: Not owner");
            _checkTransferable(tokenIds[i]);
            _transfer(msg.sender, to, tokenIds[i]);
        }
        emit BatchTransfer(msg.sender, to, tokenIds);
    }

    function batchTransferFrom(address from, address to, uint256[] calldata tokenIds) external nonReentrant {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            _checkTransferable(tokenIds[i]);
            transferFrom(from, to, tokenIds[i]);
        }
        emit BatchTransfer(from, to, tokenIds);
    }

    // ============ TOKEN LOCKING ============

    function lockToken(uint256 tokenId) external onlyLocker {
        require(_ownerOf(tokenId) != address(0), "NFTCoreV3: Token doesn't exist");
        lockedTokens[tokenId] = true;
        emit TokenLocked(tokenId, msg.sender);
    }

    function unlockToken(uint256 tokenId) external onlyLocker {
        require(lockedTokens[tokenId], "NFTCoreV3: Token not locked");
        lockedTokens[tokenId] = false;
        emit TokenUnlocked(tokenId, msg.sender);
    }

    function batchLockTokens(uint256[] calldata tokenIds) external onlyLocker {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            lockedTokens[tokenIds[i]] = true;
            emit TokenLocked(tokenIds[i], msg.sender);
        }
    }

    function batchUnlockTokens(uint256[] calldata tokenIds) external onlyLocker {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            lockedTokens[tokenIds[i]] = false;
            emit TokenUnlocked(tokenIds[i], msg.sender);
        }
    }

    // ============ SOUL-BOUND ============

    function makeSoulBound(uint256 tokenId) external {
        require(ownerOf(tokenId) == msg.sender, "NFTCoreV3: Not owner");
        require(!soulBoundTokens[tokenId], "NFTCoreV3: Already soul-bound");
        soulBoundTokens[tokenId] = true;
        emit TokenMadeSoulBound(tokenId);
    }

    // ============ BURNING ============

    function burn(uint256 tokenId) external {
        require(ownerOf(tokenId) == msg.sender, "NFTCoreV3: Not owner");
        require(!lockedTokens[tokenId], "NFTCoreV3: Token is locked");
        
        address owner = ownerOf(tokenId);
        _burn(tokenId);
        emit TokenBurned(tokenId, owner);
    }

    // ============ ADMIN ============

    function authorizeMinter(address minter) external onlyOwner {
        authorizedMinter = minter;
        emit MinterAuthorized(minter);
    }

    function authorizeLocker(address locker, bool status) external onlyOwner {
        authorizedLockers[locker] = status;
        emit LockerAuthorized(locker, status);
    }

    // ============ INTERNAL ============

    function _checkTransferable(uint256 tokenId) internal view {
        if (lockedTokens[tokenId]) revert TokenIsLocked(tokenId);
        if (soulBoundTokens[tokenId]) revert TokenIsSoulBound(tokenId);
    }

    function _update(address to, uint256 tokenId, address auth) internal override(ERC721, ERC721Enumerable) returns (address) {
        address from = _ownerOf(tokenId);
        
        // Check transferability (skip for minting/burning)
        if (from != address(0) && to != address(0)) {
            if (lockedTokens[tokenId]) revert TokenIsLocked(tokenId);
            if (soulBoundTokens[tokenId]) revert TokenIsSoulBound(tokenId);
        }
        
        return super._update(to, tokenId, auth);
    }

    function _increaseBalance(address account, uint128 value) internal override(ERC721, ERC721Enumerable) {
        super._increaseBalance(account, value);
    }

    function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721URIStorage, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    // ============ VIEW FUNCTIONS ============

    function exists(uint256 tokenId) external view returns (bool) {
        return _ownerOf(tokenId) != address(0);
    }

    function isTransferable(uint256 tokenId) external view returns (bool) {
        return !lockedTokens[tokenId] && !soulBoundTokens[tokenId];
    }

    function getTotalMinted() external view returns (uint256) {
        return _tokenIdCounter;
    }

    function getTokenInfo(uint256 tokenId) external view returns (
        address owner_,
        address creator,
        uint256 mintTime,
        bool locked,
        bool soulBound,
        string memory uri
    ) {
        require(_ownerOf(tokenId) != address(0), "NFTCoreV3: Token doesn't exist");
        return (
            ownerOf(tokenId),
            creators[tokenId],
            mintTimestamps[tokenId],
            lockedTokens[tokenId],
            soulBoundTokens[tokenId],
            tokenURI(tokenId)
        );
    }
}
