# Security Considerations

## NFTminimint Security Guide

### Access Control

#### Owner Privileges
- Deploy and link contracts
- Authorize/revoke minters
- Set royalty configurations
- Emergency pause operations

#### Admin Privileges
- Manage whitelist
- Control mint limits
- Open/close public minting
- Pause/unpause operations

#### Minter Privileges
- Mint tokens (authorized contracts only)

### Security Features

#### 1. Reentrancy Protection
All minting functions use `nonReentrant` modifier from OpenZeppelin.

#### 2. Access Modifiers
```solidity
onlyOwner      // Owner-only functions
onlyAdmin      // Admin-only functions
onlyMinter     // Authorized minter functions
onlyAuthorized // Authorized caller functions
```

#### 3. Zero Address Checks
All address parameters are validated against zero address.

#### 4. Pausable Operations
Minting can be paused in emergencies.

### Best Practices

1. **Keep owner wallet secure** - Use a hardware wallet or multisig
2. **Verify contract addresses** - Double-check before linking
3. **Test on testnet first** - Always test before mainnet
4. **Monitor authorized addresses** - Regularly audit authorized minters
5. **Use metadata freezing carefully** - It's irreversible!

### Known Considerations

1. **Max Supply**: Can be changed by owner (not locked)
2. **Royalties**: Can be modified by owner
3. **Admin roles**: Owner can add/remove admins
4. **Metadata**: Can be modified until frozen

### Emergency Procedures

#### Pause All Operations
```solidity
NFTAccess.pause()
```

#### Revoke Minter Access
```solidity
NFTCore.revokeMinter(address)
```

#### Remove Admin
```solidity
NFTAccess.setAdmin(address, false)
```

### Audit Status
⚠️ This code has not been formally audited. Use at your own risk.

### Contact
Report security issues to the repository maintainers.
