// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/**
 * @title NFTminimint
 * @dev A minimal NFT minting platform with ERC-721 standard implementation
 * @author Adekunle Bamz
 * @notice This contract allows users to mint NFTs with custom metadata and includes
 * basic functionality for NFT creation, ownership, and fund withdrawal
 */
contract NFTminimint is ERC721, ERC721URIStorage, Ownable, Pausable, ReentrancyGuard {
    uint256 private _tokenIdCounter;

    uint256 public mintFee;
    uint256 public maxSupply;
    uint256 public maxPerWallet;

    mapping(address => uint256) public mintedByWallet;

    error InsufficientMintFee(uint256 sent, uint256 required);
    error SoldOut();
    error WalletLimitExceeded();
    error ZeroAddress();
    error NoFundsToWithdraw();
    error WithdrawFailed();
    error InvalidQuantity();
    error ExceedsMaxBatchSize();

    event MintFeeUpdated(uint256 previousFee, uint256 newFee);
    event MaxSupplyUpdated(uint256 previousMaxSupply, uint256 newMaxSupply);
    event MaxPerWalletUpdated(uint256 previousMaxPerWallet, uint256 newMaxPerWallet);
    event BatchMinted(address indexed to, uint256 startTokenId, uint256 quantity);

    uint256 public constant MAX_BATCH_SIZE = 10;

    /**
     * @dev Emitted when an NFT is successfully minted
     * @param to The address that received the NFT
     * @param tokenId The ID of the minted token
     * @param tokenURI The metadata URI for the token
     */
    event NFTMinted(address indexed to, uint256 indexed tokenId, string tokenURI);

    /**
     * @dev Constructor initializes the ERC721 token with name and symbol
     * @param name The name of the NFT collection
     * @param symbol The symbol for the NFT collection
     */
    constructor() ERC721("NFTminimint", "NFTM") {
        mintFee = 0.01 ether;
        maxSupply = 1024;
        maxPerWallet = 10;
    }

    /**
     * @notice Mint a new NFT with custom metadata
     * @dev Mints a new NFT to the specified address with the given token URI
     * @param to The address that will receive the minted NFT
     * @param tokenURI The metadata URI for the NFT (should conform to ERC-721 metadata standard)
     */
    function mintNFT(address to, string memory tokenURI) external payable whenNotPaused {
        if (to == address(0)) revert ZeroAddress();
        if (_tokenIdCounter >= maxSupply) revert SoldOut();
        if (mintedByWallet[msg.sender] >= maxPerWallet) revert WalletLimitExceeded();
        if (msg.value < mintFee) revert InsufficientMintFee(msg.value, mintFee);

        uint256 tokenId = _tokenIdCounter;
        _tokenIdCounter++;

        mintedByWallet[msg.sender] += 1;

        _safeMint(to, tokenId);
        _setTokenURI(tokenId, tokenURI);

        emit NFTMinted(to, tokenId, tokenURI);
    }

    /**
     * @notice Batch mint multiple NFTs at once
     * @dev Mints multiple NFTs to the specified address with the given token URIs
     * @param to The address that will receive the minted NFTs
     * @param tokenURIs Array of metadata URIs for the NFTs
     */
    function batchMint(address to, string[] calldata tokenURIs) external payable whenNotPaused {
        uint256 quantity = tokenURIs.length;
        
        if (to == address(0)) revert ZeroAddress();
        if (quantity == 0) revert InvalidQuantity();
        if (quantity > MAX_BATCH_SIZE) revert ExceedsMaxBatchSize();
        if (_tokenIdCounter + quantity > maxSupply) revert SoldOut();
        if (mintedByWallet[msg.sender] + quantity > maxPerWallet) revert WalletLimitExceeded();
        if (msg.value < mintFee * quantity) revert InsufficientMintFee(msg.value, mintFee * quantity);

        uint256 startTokenId = _tokenIdCounter;
        
        for (uint256 i = 0; i < quantity; i++) {
            uint256 tokenId = _tokenIdCounter;
            _tokenIdCounter++;
            
            _safeMint(to, tokenId);
            _setTokenURI(tokenId, tokenURIs[i]);
            
            emit NFTMinted(to, tokenId, tokenURIs[i]);
        }
        
        mintedByWallet[msg.sender] += quantity;
        emit BatchMinted(to, startTokenId, quantity);
    }

    function ownerMint(address to, string memory tokenURI) external onlyOwner {
        if (to == address(0)) revert ZeroAddress();
        if (_tokenIdCounter >= maxSupply) revert SoldOut();

        uint256 tokenId = _tokenIdCounter;
        _tokenIdCounter++;

        _safeMint(to, tokenId);
        _setTokenURI(tokenId, tokenURI);

        emit NFTMinted(to, tokenId, tokenURI);
    }

    function setMintFee(uint256 newMintFee) external onlyOwner {
        uint256 previous = mintFee;
        mintFee = newMintFee;
        emit MintFeeUpdated(previous, newMintFee);
    }

    function setMaxSupply(uint256 newMaxSupply) external onlyOwner {
        require(newMaxSupply >= _tokenIdCounter, "maxSupply < totalSupply");
        uint256 previous = maxSupply;
        maxSupply = newMaxSupply;
        emit MaxSupplyUpdated(previous, newMaxSupply);
    }

    function setMaxPerWallet(uint256 newMaxPerWallet) external onlyOwner {
        uint256 previous = maxPerWallet;
        maxPerWallet = newMaxPerWallet;
        emit MaxPerWalletUpdated(previous, newMaxPerWallet);
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    /**
     * @notice Get remaining mintable supply
     * @return The number of NFTs that can still be minted
     */
    function remainingSupply() external view returns (uint256) {
        return maxSupply - _tokenIdCounter;
    }

    /**
     * @notice Get remaining mints for a wallet
     * @param wallet The wallet address to check
     * @return The number of NFTs the wallet can still mint
     */
    function remainingForWallet(address wallet) external view returns (uint256) {
        uint256 minted = mintedByWallet[wallet];
        if (minted >= maxPerWallet) return 0;
        return maxPerWallet - minted;
    }

    /**
     * @notice Check if an address can mint
     * @param wallet The wallet address to check
     * @return True if the wallet can mint at least one NFT
     */
    function canMint(address wallet) external view returns (bool) {
        if (paused()) return false;
        if (_tokenIdCounter >= maxSupply) return false;
        if (mintedByWallet[wallet] >= maxPerWallet) return false;
        return true;
    }

    /**
     * @notice Get minting cost for a quantity
     * @param quantity Number of NFTs to mint
     * @return Total cost in wei
     */
    function getMintCost(uint256 quantity) external view returns (uint256) {
        return mintFee * quantity;
    }

    /**
     * @notice Get the token URI for a specific NFT
     * @dev Returns the metadata URI for the specified token ID
     * @param tokenId The ID of the token to query
     * @return The token URI string
     */
    function getTokenURI(uint256 tokenId) external view returns (string memory) {
        return tokenURI(tokenId);
    }

    /**
     * @notice Get the total supply of minted NFTs
     * @dev Returns the total number of NFTs minted so far
     * @return The total supply as a uint256
     */
    function totalSupply() external view returns (uint256) {
        return _tokenIdCounter;
    }

    // Override functions
    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721URIStorage) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    /**
     * @notice Withdraw contract balance
     * @dev Allows the contract owner to withdraw accumulated funds from NFT minting fees
     * @dev Only callable by the contract owner
     */
    function withdraw(address payable to) external onlyOwner nonReentrant {
        if (to == address(0)) revert ZeroAddress();
        uint256 balance = address(this).balance;
        if (balance == 0) revert NoFundsToWithdraw();

        (bool ok, ) = to.call{value: balance}("");
        if (!ok) revert WithdrawFailed();
    }
}
