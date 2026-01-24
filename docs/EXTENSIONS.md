# Extensions Guide

## Available Extensions

NFTminimint includes several optional extension contracts that add additional functionality.

### NFTEmergency
Emergency operations for contract recovery.

**Features:**
- Emergency ETH withdrawal
- Balance checking

**Usage:**
```solidity
import "./extensions/NFTEmergency.sol";

contract MyNFT is NFTCore, NFTEmergency {
    // Inherits emergency functions
}
```

### NFTTimeLock
Time-based minting restrictions.

**Features:**
- Set mint start time
- Set mint end time
- Time window validation

**Usage:**
```solidity
import "./extensions/NFTTimeLock.sol";

contract MyNFT is NFTCore, NFTTimeLock {
    function setMintWindow(uint256 start, uint256 end) external onlyOwner {
        _setMintWindow(start, end);
    }
    
    function mint() external {
        require(isMintWindowOpen(), "Mint window closed");
        // mint logic
    }
}
```

### NFTReveal
Delayed metadata reveal for fair launches.

**Features:**
- Hidden metadata before reveal
- One-time reveal function
- Automatic URI switching

**Usage:**
```solidity
import "./extensions/NFTReveal.sol";

contract MyNFT is NFTCore, NFTReveal {
    function setHiddenURI(string memory uri) external onlyOwner {
        _setHiddenMetadataURI(uri);
    }
    
    function reveal(string memory baseURI) external onlyOwner {
        _reveal(baseURI);
    }
}
```

### NFTBurnable
Enhanced token burning with tracking.

**Features:**
- Burn tracking
- Burn history
- Enable/disable burning

**Usage:**
```solidity
import "./extensions/NFTBurnable.sol";

contract MyNFT is NFTCore, NFTBurnable {
    function burn(uint256 tokenId) external {
        _recordBurn(tokenId, msg.sender);
        _burn(tokenId);
    }
}
```

### NFTOperatorFilter
Marketplace operator restrictions.

**Features:**
- Block specific operators
- Enable/disable filtering
- Operator validation

**Usage:**
```solidity
import "./extensions/NFTOperatorFilter.sol";

contract MyNFT is NFTCore, NFTOperatorFilter {
    function blockMarketplace(address marketplace) external onlyOwner {
        _blockOperator(marketplace);
    }
    
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }
}
```

### NFTStaking
Token staking functionality.

**Features:**
- Lock tokens
- Track staking duration
- Staking rewards integration

**Usage:**
```solidity
import "./extensions/NFTStaking.sol";

contract MyNFT is NFTCore, NFTStaking {
    function stake(uint256 tokenId) external {
        require(ownerOf(tokenId) == msg.sender, "Not owner");
        _stake(tokenId, msg.sender);
    }
    
    function unstake(uint256 tokenId) external {
        require(stakes[tokenId].staker == msg.sender, "Not staker");
        uint256 duration = _unstake(tokenId);
        // Give rewards based on duration
    }
}
```

### NFTGated
Token-gated access and feature unlocking.

**Features:**
- Feature registry with min token requirements
- Time-based access windows
- Access logging

**Usage:**
```solidity
import "./extensions/NFTGated.sol";

contract MyNFT is NFTCore, NFTGated {
    function createFeature(string memory name, uint256 minTokens) external onlyOwner {
        _createFeature(name, minTokens, block.timestamp, 0);
    }
    
    function access(bytes32 featureId) external {
        require(_canAccessFeature(featureId, balanceOf(msg.sender)), "Access denied");
        _recordAccess(featureId, msg.sender);
    }
}
```

### NFTPermit
Signature-based approvals (EIP-4494).

**Features:**
- Off-chain approvals via signatures
- Nonce replay protection
- EIP-712 domain separation

**Usage:**
```solidity
import "./extensions/NFTPermit.sol";

contract MyNFT is NFTCore, NFTPermit {
    constructor(string memory name_, string memory symbol_) NFTCore(name_, symbol_) {
        _initPermit(name_);
    }
    
    function _ownerOfPermit(uint256 tokenId) internal view override returns (address) {

    ### NFTMerkleAllowance
    Merkle allowlist where each address has an explicit mint allowance.

    **Features:**
    - Merkle root verification with `(account, allowance)` leaf
    - Track claimed quantity per wallet
    - Enable/disable allowance minting

    **Usage:**
    ```solidity
    import "./extensions/NFTMerkleAllowance.sol";

    contract MyNFT is NFTCore, NFTMerkleAllowance {
        function setAllowanceRoot(bytes32 root) external onlyOwner {
            _setAllowanceMerkleRoot(root);
        }

        function setAllowanceEnabled(bool enabled) external onlyOwner {
            _setAllowanceMintEnabled(enabled);
        }

        function allowlistMint(uint256 quantity, uint256 allowance, bytes32[] calldata proof) external {
            _validateAndConsumeAllowance(proof, msg.sender, quantity, allowance);
            // mint `quantity` tokens
        }
    }
    ```
        return _ownerOf(tokenId);
    }
    
    function _approvePermit(address spender, uint256 tokenId) internal override {
        _approve(spender, tokenId);
    }
}
```

### NFTTransferCooldown
Enforces a minimum time interval between transfers for the same token.

**Features:**
- Global cooldown seconds
- Per-token last transfer timestamp tracking
- Hook-style `_checkTransferCooldown()` for ERC721 transfer integration

**Usage:**
```solidity
import "./extensions/NFTTransferCooldown.sol";

contract MyNFT is ERC721, NFTTransferCooldown {
    function setCooldown(uint256 seconds_) external onlyOwner {
        _setTransferCooldown(seconds_);
    }

    function _update(address to, uint256 tokenId, address auth) internal override returns (address) {
        address from = _ownerOf(tokenId);
        if (from != address(0) && to != address(0)) {
            _checkTransferCooldown(tokenId);
        }

        address prev = super._update(to, tokenId, auth);

        if (from != address(0) && to != address(0)) {
            _recordTransfer(tokenId);
        }

        return prev;
    }
}
```

### NFTMetadataFreeze
Permanently freezes metadata updates (useful for trust-minimized collections).

**Features:**
- One-way freeze switch
- Guard helper for setters

**Usage:**
```solidity
import "./extensions/NFTMetadataFreeze.sol";

contract MyNFT is NFTCore, NFTMetadataFreeze {
    function setBaseURI(string memory newBaseURI) external onlyOwner {
        _requireMetadataNotFrozen();
        // update base URI
    }

    function freezeMetadata() external onlyOwner {
        _freezeMetadata();
    }
}
```

### NFTBatchMintLimit
Restricts the maximum number of tokens that can be minted in a single batch.

**Features:**
- Configurable max batch size
- Guard helper for batch mint flows

**Usage:**
```solidity
import "./extensions/NFTBatchMintLimit.sol";

contract MyNFT is NFTCore, NFTBatchMintLimit {
    function setMaxBatch(uint256 maxBatch) external onlyOwner {
        _setMaxBatchMint(maxBatch);
    }

    function batchMint(uint256 quantity) external {
        _checkBatchMint(quantity);
        // mint `quantity` tokens
    }
}
```

### NFTMintCooldown
Enforces a minimum time interval between mints for the same wallet.

**Features:**
- Global cooldown seconds
- Per-wallet last mint timestamp

**Usage:**
```solidity
import "./extensions/NFTMintCooldown.sol";

contract MyNFT is NFTCore, NFTMintCooldown {
    function setMintCooldown(uint256 seconds_) external onlyOwner {
        _setMintCooldown(seconds_);
    }

    function mint() external {
        _checkMintCooldown(msg.sender);
        // mint token
        _recordMintCooldown(msg.sender);
    }
}
```

### NFTTransferAllowlist
Restricts transfers so only approved recipient addresses can receive tokens.

**Features:**
- Enable/disable recipient allowlist
- Per-recipient allowlist mapping

**Usage:**
```solidity
import "./extensions/NFTTransferAllowlist.sol";

contract MyNFT is ERC721, NFTTransferAllowlist {
    function setAllowlistEnabled(bool enabled) external onlyOwner {
        _setTransferAllowlistEnabled(enabled);
    }

    function setRecipientAllowed(address account, bool allowed) external onlyOwner {
        _setRecipientAllowed(account, allowed);
    }

    function _update(address to, uint256 tokenId, address auth) internal override returns (address) {
        address from = _ownerOf(tokenId);
        if (from != address(0) && to != address(0)) {
            _checkTransferRecipient(to);
        }
        return super._update(to, tokenId, auth);
    }
}
```

### NFTSupplyBuffer
Reserves a buffer of unminted supply (e.g., keep $n$ tokens unminted).

**Features:**
- Configurable supply buffer
- Guard helper for mint flows

**Usage:**
```solidity
import "./extensions/NFTSupplyBuffer.sol";

contract MyNFT is NFTCore, NFTSupplyBuffer {
    function setSupplyBuffer(uint256 buffer) external onlyOwner {
        _setSupplyBuffer(buffer);
    }

    function mint(uint256 quantity) external {
        _checkSupplyBuffer(totalSupply(), maxSupply(), quantity);
        // mint `quantity` tokens
    }
}
```

### NFTWalletCap
Caps the maximum number of tokens a wallet can mint/hold.

**Features:**
- Configurable max per wallet
- Guard helper for mint flows

**Usage:**
```solidity
import "./extensions/NFTWalletCap.sol";

contract MyNFT is NFTCore, NFTWalletCap {
    function setMaxPerWallet(uint256 maxPerWallet) external onlyOwner {
        _setMaxPerWallet(maxPerWallet);
    }

    function mint(uint256 quantity) external {
        _checkWalletCap(balanceOf(msg.sender), quantity);
        // mint `quantity` tokens
    }
}
```

### NFTTokenLockup
Locks individual tokens until a specific timestamp.

**Features:**
- Per-token lock timestamp
- Guard helper for transfer hooks

**Usage:**
```solidity
import "./extensions/NFTTokenLockup.sol";

contract MyNFT is ERC721, NFTTokenLockup {
    function lock(uint256 tokenId, uint256 untilTimestamp) external onlyOwner {
        _lockToken(tokenId, untilTimestamp);
    }

    function _update(address to, uint256 tokenId, address auth) internal override returns (address) {
        address from = _ownerOf(tokenId);
        if (from != address(0) && to != address(0)) {
            _checkTokenLockup(tokenId);
        }
        return super._update(to, tokenId, auth);
    }
}
```

### NFTBlacklist
Blocks mints and transfers to specific addresses.

**Features:**
- Per-address blacklist mapping
- Guard helper for mint/transfer flows

**Usage:**
```solidity
import "./extensions/NFTBlacklist.sol";

contract MyNFT is ERC721, NFTBlacklist {
    function setBlacklisted(address account, bool blacklisted) external onlyOwner {
        _setBlacklisted(account, blacklisted);
    }

    function mint(address to) external {
        _checkNotBlacklisted(to);
        // mint token
    }

    function _update(address to, uint256 tokenId, address auth) internal override returns (address) {
        address from = _ownerOf(tokenId);
        if (from != address(0) && to != address(0)) {
            _checkNotBlacklisted(to);
        }
        return super._update(to, tokenId, auth);
    }
}
```

## Best Practices

1. **Don't inherit all extensions** - Only use what you need
2. **Test thoroughly** - Extensions may interact unexpectedly
3. **Check gas costs** - More extensions = higher gas
4. **Review security** - Some extensions add attack surface

### NFTMaxSupplyChange
Dynamic supply reduction.

**Features:**
- Reduce max supply
- Prevent supply increase
- Safety validation

**Usage:**
```solidity
import "./extensions/NFTMaxSupplyChange.sol";

contract MyNFT is NFTCore, NFTMaxSupplyChange {
    function reduceMaxSupply(uint256 newMax) external onlyOwner {
        _reduceMaxSupply(newMax);
    }
}
```

### NFTFreeMint
Claimable free mints for specific users.

**Features:**
- Allowlist for free mints
- Cap per wallet
- Global enable/disable switch

**Usage:**
```solidity
import "./extensions/NFTFreeMint.sol";

contract MyNFT is NFTCore, NFTFreeMint {
    function setFreeList(address[] calldata users, bool status) external onlyOwner {
        for(uint i=0; i<users.length; i++) {
            _setFreeMintAccess(users[i], status);
        }
    }
}
```

### NFTRoyalty
ERC2981 Royalty Standard implementation.

**Features:**
- Default royalty
- Per-token royalty
- ERC2981 compliance

**Usage:**
```solidity
import "./extensions/NFTRoyalty.sol";

contract MyNFT is NFTCore, NFTRoyalty {
    function setRoyalty(address receiver, uint96 feeNumerator) external onlyOwner {
        _setDefaultRoyalty(receiver, feeNumerator);
    }
    
    // Override supportsInterface to include ERC2981
    function supportsInterface(bytes4 interfaceId) public view override(NFTCore, ERC2981) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
```

### NFTEnumerable
Full token enumeration support.

**Features:**
- On-chain token enumeration
- Wallet inventory tracking
- Total supply tracking

**Usage:**
```solidity
import "./extensions/NFTEnumerable.sol";

contract MyNFT is NFTCore, NFTEnumerable {
    // Override _update, _increaseBalance, and supportsInterface
    function _update(address to, uint256 tokenId, address auth) internal override(ERC721, ERC721Enumerable) returns (address) {
        return super._update(to, tokenId, auth);
    }
    
    function _increaseBalance(address account, uint128 value) internal override(ERC721, ERC721Enumerable) {
        super._increaseBalance(account, value);
    }
    
    function supportsInterface(bytes4 interfaceId) public view override(NFTCore, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
    
    // Override totalSupply to resolve conflict
    function totalSupply() public view override(NFTCore, ERC721Enumerable) returns (uint256) {
        return ERC721Enumerable.totalSupply();
    }
}
```


### NFTStaking
Native token staking support.

**Features:**
- On-chain staking mechanism
- Transfer protection for staked tokens
- Staking history and duration

**Usage:**
```solidity
import "./extensions/NFTStaking.sol";

contract MyNFT is NFTCore, NFTStaking {
    function stake(uint256 tokenId) external {
        require(ownerOf(tokenId) == msg.sender, "Not owner");
        _stake(tokenId, msg.sender);
    }
    
    function unstake(uint256 tokenId) external {
        require(stakes[tokenId].staker == msg.sender, "Not staker");
        _unstake(tokenId);
    }
    
    function _update(address to, uint256 tokenId, address auth) internal override returns (address) {
        if (_ownerOf(tokenId) != address(0)) {
            require(!isStaked(tokenId), "Token is staked");
        }
        return super._update(to, tokenId, auth);
    }
}
```

### NFTReferral
Referral tracking and reward accounting.

**Features:**
- Referral count tracking
- Reward balance management
- Claimable reward events

**Usage:**
```solidity
import "./extensions/NFTReferral.sol";

contract MyNFT is NFTCore, NFTReferral {
    function mintWithReferral(address to, string memory uri, address referrer) external onlyOwner {
        mint(to, uri);
        if (referrer != address(0) && referrer != to) {
            _recordReferral(referrer, to);
            _addReward(referrer, 10);
        }
    }
    
    function claimReward(uint256 amount) external {
        _claimReward(msg.sender, amount);
    }
}
```

### NFTLazyMint
Voucher-based lazy minting.

**Features:**
- Signed voucher verification
- One-time voucher redemption
- Voucher signer management

**Usage:**
```solidity
import "./extensions/NFTLazyMint.sol";

contract MyNFT is NFTCore, NFTLazyMint {
    function setVoucherSigner(address signer) external onlyOwner {
        _setVoucherSigner(signer);
    }

    function redeemVoucher(MintVoucher calldata voucher) external payable {
        require(_verifyVoucher(voucher), "Invalid voucher");
        _useVoucher(voucher);
        // mint logic here
    }
}
```

### NFTCrosschain
Cross-chain bridge request tracking.

**Features:**
- Destination chain allowlist
- Bridge request creation and processing
- Token lock during bridging

**Usage:**
```solidity
import "./extensions/NFTCrosschain.sol";

contract MyNFT is NFTCore, NFTCrosschain {
    function setBridgeOperator(address operator) external onlyOwner {
        _setBridgeOperator(operator);
    }

    function setSupportedChain(uint256 chainId, bool supported) external onlyOwner {
        _setSupportedChain(chainId, supported);
    }

    function requestBridge(uint256 tokenId, uint256 destinationChainId) external {
        require(ownerOf(tokenId) == msg.sender, "Not owner");
        _createBridgeRequest(tokenId, msg.sender, destinationChainId);
    }
}
```

### NFTAllowlist
Merkle-tree allowlist minting.

**Features:**
- Merkle root allowlist verification
- One-time claim tracking
- Toggle allowlist minting

**Usage:**
```solidity
import "./extensions/NFTAllowlist.sol";

contract MyNFT is NFTCore, NFTAllowlist {
    function setMerkleRoot(bytes32 root) external onlyOwner {
        _setMerkleRoot(root);
    }

    function setAllowlistEnabled(bool enabled) external onlyOwner {
        _setAllowlistMintEnabled(enabled);
    }

    function allowlistMint(bytes32[] calldata proof, string memory uri) external {
        require(isAllowlistMintEnabled(), "Allowlist mint disabled");
        require(_verifyProof(proof, msg.sender), "Not on allowlist");
        _markAllowlistClaimed(msg.sender);
        mint(msg.sender, uri);
    }
}
```

### NFTProvenance
Token history and provenance tracking.

**Features:**
- Mint, transfer, and sale event recording
- Original creator tracking
- On-chain provenance history

**Usage:**
```solidity
import "./extensions/NFTProvenance.sol";

contract MyNFT is NFTCore, NFTProvenance {
    function mintWithProvenance(address to, string memory uri) external onlyOwner {
        uint256 tokenId = mint(to, uri);
        _recordMint(tokenId, to);
    }
    
    function recordTransfer(uint256 tokenId, address from, address to) external onlyOwner {
        _recordTransfer(tokenId, from, to);
    }
}
```

### NFTRandomMint
Randomized token ID assignment.

**Features:**
- Fisher-Yates shuffle selection
- Remaining supply tracking
- Configurable max supply

**Usage:**
```solidity
import "./extensions/NFTRandomMint.sol";

contract MyNFT is NFTCore, NFTRandomMint {
    function initializeRandomMint(uint256 maxSupply) external onlyOwner {
        _initializeRandomMint(maxSupply);
    }

    function randomMint(address to, uint256 nonce) external onlyOwner {
        uint256 tokenId = _getRandomTokenId(nonce);
        // mint tokenId to user
    }
}
```
