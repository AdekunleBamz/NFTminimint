# API Reference

## NFTCore

### Write Functions

#### `mint(address to, string uri) → uint256`
Mint a new token to the specified address.
- **Access**: Authorized minters only
- **Returns**: Token ID

#### `batchMint(address to, string[] uris) → uint256`
Batch mint multiple tokens.
- **Access**: Authorized minters only
- **Limit**: Max 50 per batch
- **Returns**: First token ID

#### `authorizeMinter(address minter)`
Authorize an address to mint tokens.
- **Access**: Owner only

#### `revokeMinter(address minter)`
Revoke minting authorization.
- **Access**: Owner only

#### `setBaseURI(string baseURI)`
Set the base URI for all tokens.
- **Access**: Owner only

#### `setTokenURI(uint256 tokenId, string uri)`
Update a specific token's URI.
- **Access**: Owner only

### Read Functions

#### `totalMinted() → uint256`
Get total number of tokens minted.

#### `totalBurned() → uint256`
Get total number of tokens burned.

#### `circulatingSupply() → uint256`
Get current circulating supply (minted - burned).

#### `exists(uint256 tokenId) → bool`
Check if a token exists.

#### `tokensOfOwner(address owner) → uint256[]`
Get all tokens owned by an address.

#### `getTokenCreationInfo(uint256 tokenId) → (address creator, uint256 timestamp)`
Get creation info for a token.

#### `isMinterAuthorized(address minter) → bool`
Check if an address is authorized to mint.

---

## NFTMetadata

### Write Functions

#### `setAttribute(uint256 tokenId, string key, string value)`
Set an attribute on a token.
- **Access**: Owner only

#### `removeAttribute(uint256 tokenId, string key)`
Remove an attribute from a token.
- **Access**: Owner only

#### `freezeMetadata()`
Freeze all metadata permanently.
- **Access**: Owner only
- **Warning**: Irreversible!

#### `freezeTokenMetadata(uint256 tokenId)`
Freeze a specific token's metadata.
- **Access**: Owner only
- **Warning**: Irreversible!

#### `setContractURI(string uri)`
Set the contract-level metadata URI.
- **Access**: Owner only

### Read Functions

#### `getAttribute(uint256 tokenId, string key) → string`
Get an attribute value.

#### `getAttributeKeys(uint256 tokenId) → string[]`
Get all attribute keys for a token.

#### `metadataFrozen() → bool`
Check if global metadata is frozen.

#### `tokenMetadataFrozen(uint256 tokenId) → bool`
Check if a token's metadata is frozen.

#### `contractURI() → string`
Get the contract metadata URI.

---

## NFTAccess

### Write Functions

#### `addToWhitelist(address account)`
Add address to whitelist.
- **Access**: Admin only

#### `removeFromWhitelist(address account)`
Remove address from whitelist.
- **Access**: Admin only

#### `batchAddToWhitelist(address[] accounts)`
Batch add to whitelist.
- **Access**: Admin only

#### `setWhitelistEnabled(bool enabled)`
Enable or disable whitelist requirement.
- **Access**: Admin only

#### `setPublicMintOpen(bool open)`
Open or close public minting.
- **Access**: Admin only

#### `setWalletMintLimit(uint256 limit)`
Set per-wallet mint limit.
- **Access**: Admin only
- **Note**: 0 = unlimited

#### `pause()` / `unpause()`
Pause or unpause all minting.
- **Access**: Admin only

#### `setAdmin(address admin, bool status)`
Grant or revoke admin status.
- **Access**: Owner only

### Read Functions

#### `canMint(address account) → (bool canMint, string reason)`
Check if an address can mint.

#### `isWhitelisted(address account) → bool`
Check if address is whitelisted.

#### `isAdmin(address account) → bool`
Check if address is admin.

#### `getMintStats(address wallet) → (uint256 minted, uint256 remaining, uint256 limit)`
Get minting statistics for a wallet.

---

## NFTCollection

### Write Functions

#### `setMaxSupply(uint256 newMaxSupply)`
Update the maximum supply.
- **Access**: Owner only

#### `setDefaultRoyalty(address receiver, uint96 feeNumerator)`
Set default royalty for all tokens.
- **Access**: Owner only
- **Fee**: In basis points (500 = 5%)

#### `setTokenRoyalty(uint256 tokenId, address receiver, uint96 feeNumerator)`
Set royalty for a specific token.
- **Access**: Owner only

#### `deleteDefaultRoyalty()`
Remove default royalty.
- **Access**: Owner only

#### `deleteTokenRoyalty(uint256 tokenId)`
Remove token-specific royalty.
- **Access**: Owner only

### Read Functions

#### `maxSupply() → uint256`
Get maximum supply.

#### `remainingSupply() → uint256`
Get remaining mintable supply.

#### `canMintAmount(uint256 amount) → bool`
Check if amount can be minted.

#### `royaltyInfo(uint256 tokenId, uint256 salePrice) → (address receiver, uint256 royaltyAmount)`
Get royalty info (EIP-2981).

---

## NFTminimint

### Write Functions

#### `mint(string tokenURI) → uint256`
Mint a FREE NFT to caller.
- **Returns**: Token ID

#### `mintTo(address to, string tokenURI) → uint256`
Mint a FREE NFT to specified address.
- **Returns**: Token ID

#### `batchMint(string[] tokenURIs) → uint256`
Batch mint FREE NFTs to caller.
- **Returns**: First token ID

#### `airdrop(address[] recipients, string[] tokenURIs)`
Airdrop FREE NFTs to multiple recipients.
- **Access**: Owner only
