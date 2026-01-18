// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title NFTminimint
 * @dev A minimal NFT minting platform with ERC-721 standard implementation
 * @author Adekunle Bamz
 * @notice This contract allows users to mint NFTs with custom metadata and includes
 * basic functionality for NFT creation, ownership, and fund withdrawal
 */
contract NFTminimint is ERC721, ERC721URIStorage, Ownable {
    uint256 private _tokenIdCounter;
    uint256 public constant MINT_FEE = 0.01 ether;

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
    constructor() ERC721("NFTminimint", "NFTM") Ownable(msg.sender) {}

    /**
     * @notice Mint a new NFT with custom metadata
     * @dev Mints a new NFT to the specified address with the given token URI
     * @param to The address that will receive the minted NFT
     * @param tokenURI The metadata URI for the NFT (should conform to ERC-721 metadata standard)
     */
    function mintNFT(address to, string memory tokenURI) external payable {
        require(msg.value >= MINT_FEE, "Insufficient minting fee");

        uint256 tokenId = _tokenIdCounter;
        _tokenIdCounter++;

        _safeMint(to, tokenId);
        _setTokenURI(tokenId, tokenURI);

        emit NFTMinted(to, tokenId, tokenURI);
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
    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No funds to withdraw");
        payable(owner()).transfer(balance);
    }
}
