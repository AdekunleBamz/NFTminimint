/**
 * @title Contract ABIs
 * @description Simplified ABIs for frontend integration
 */

export const NFTCoreABI = [
    "function name() view returns (string)",
    "function symbol() view returns (string)",
    "function totalSupply() view returns (uint256)",
    "function ownerOf(uint256 tokenId) view returns (address)",
    "function balanceOf(address owner) view returns (uint256)",
    "function tokenURI(uint256 tokenId) view returns (string)",
    "function getCreator(uint256 tokenId) view returns (address)",
    "function tokenExists(uint256 tokenId) view returns (bool)",
    "function mintTo(address to, string tokenURI) returns (uint256)",
    "function batchMintTo(address to, string[] tokenURIs) returns (uint256)",
    "function authorizeMinter(address minter)",
    "function revokeMinter(address minter)",
    "function approve(address to, uint256 tokenId)",
    "function setApprovalForAll(address operator, bool approved)",
    "function transferFrom(address from, address to, uint256 tokenId)",
    "function safeTransferFrom(address from, address to, uint256 tokenId)",
    "event Transfer(address indexed from, address indexed to, uint256 indexed tokenId)",
    "event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId)",
    "event ApprovalForAll(address indexed owner, address indexed operator, bool approved)",
    "event NFTMinted(uint256 indexed tokenId, address indexed to, address indexed creator, string tokenURI)"
];

export const NFTAccessABI = [
    "function isPublicMintOpen() view returns (bool)",
    "function isPaused() view returns (bool)",
    "function isWhitelisted(address account) view returns (bool)",
    "function getWalletMintLimit() view returns (uint256)",
    "function mintedPerWallet(address wallet) view returns (uint256)",
    "function canMint(address minter, uint256 quantity) view returns (bool)",
    "function isAdmin(address account) view returns (bool)",
    "function setPublicMintOpen(bool isOpen)",
    "function setWhitelistEnabled(bool enabled)",
    "function addToWhitelist(address account)",
    "function removeFromWhitelist(address account)",
    "function batchAddToWhitelist(address[] accounts)",
    "function setWalletMintLimit(uint256 limit)",
    "function setPaused(bool paused)",
    "function authorizeCaller(address caller)",
    "function recordMint(address minter, uint256 quantity)",
    "event WhitelistUpdated(address indexed account, bool status)",
    "event PublicMintStatusChanged(bool isOpen)",
    "event PauseStatusChanged(bool isPaused)"
];

export const NFTMetadataABI = [
    "function contractURI() view returns (string)",
    "function getAttribute(uint256 tokenId, string key) view returns (string)",
    "function isMetadataFrozen(uint256 tokenId) view returns (bool)",
    "function getAttributeKeys(uint256 tokenId) view returns (string[])",
    "function setContractURI(string uri)",
    "function setAttribute(uint256 tokenId, string key, string value)",
    "function setMultipleAttributes(uint256 tokenId, string[] keys, string[] values)",
    "function removeAttribute(uint256 tokenId, string key)",
    "function freezeMetadata(uint256 tokenId)",
    "function authorizeCaller(address caller)",
    "event ContractURIUpdated(string newURI)",
    "event AttributeSet(uint256 indexed tokenId, string key, string value)",
    "event MetadataFrozen(uint256 indexed tokenId)"
];

export const NFTCollectionABI = [
    "function maxSupply() view returns (uint256)",
    "function currentSupply() view returns (uint256)",
    "function remainingSupply() view returns (uint256)",
    "function royaltyInfo(uint256 tokenId, uint256 salePrice) view returns (address, uint256)",
    "function setMaxSupply(uint256 newMaxSupply)",
    "function setDefaultRoyalty(address receiver, uint96 feeNumerator)",
    "function setTokenRoyalty(uint256 tokenId, address receiver, uint96 feeNumerator)",
    "function deleteDefaultRoyalty()",
    "function authorizeCaller(address caller)",
    "function incrementSupply(uint256 quantity)",
    "event MaxSupplyUpdated(uint256 oldSupply, uint256 newSupply)",
    "event DefaultRoyaltySet(address indexed receiver, uint96 bps)"
];

export const NFTMinimintABI = [
    "function nftCore() view returns (address)",
    "function nftMetadata() view returns (address)",
    "function nftAccess() view returns (address)",
    "function nftCollection() view returns (address)",
    "function mint(string tokenURI) returns (uint256)",
    "function batchMint(string[] tokenURIs) returns (uint256)",
    "function airdrop(address[] recipients, string[] tokenURIs)",
    "function mintWithAttribute(string tokenURI, string key, string value) returns (uint256)",
    "function setRoyalty(address receiver, uint96 bps)",
    "function pause()",
    "function unpause()",
    "event Minted(address indexed to, uint256 indexed tokenId, string tokenURI)",
    "event BatchMinted(address indexed to, uint256 startTokenId, uint256 quantity)",
    "event Airdropped(address[] recipients, uint256[] tokenIds)"
];

// Full ABIs for advanced usage
export const FULL_ABIS = {
    NFTCore: NFTCoreABI,
    NFTAccess: NFTAccessABI,
    NFTMetadata: NFTMetadataABI,
    NFTCollection: NFTCollectionABI,
    NFTMinimint: NFTMinimintABI
};
