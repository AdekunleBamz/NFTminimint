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

## Best Practices

1. **Don't inherit all extensions** - Only use what you need
2. **Test thoroughly** - Extensions may interact unexpectedly
3. **Check gas costs** - More extensions = higher gas
4. **Review security** - Some extensions add attack surface
