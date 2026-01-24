// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title NFTCrosschain
 * @dev Extension for cross-chain NFT bridging preparation
 */
abstract contract NFTCrosschain {
    
    struct BridgeRequest {
        uint256 tokenId;
        address owner;
        uint256 destinationChainId;
        bytes32 bridgeHash;
        uint256 timestamp;
        bool processed;
    }
    
    mapping(bytes32 => BridgeRequest) private _bridgeRequests;
    mapping(uint256 => bool) private _lockedTokens;
    mapping(uint256 => bool) private _supportedChains;
    
    address private _bridgeOperator;
    
    event BridgeRequestCreated(
        bytes32 indexed requestId,
        uint256 indexed tokenId,
        address indexed owner,
        uint256 destinationChainId
    );
    event BridgeRequestProcessed(bytes32 indexed requestId, bool success);
    event TokenLocked(uint256 indexed tokenId, uint256 destinationChainId);
    event TokenUnlocked(uint256 indexed tokenId);
    event ChainSupportUpdated(uint256 indexed chainId, bool supported);
    
    /**
     * @dev Set bridge operator
     */
    function _setBridgeOperator(address operator) internal {
        _bridgeOperator = operator;
    }
    
    /**
     * @dev Add/remove supported destination chain
     */
    function _setSupportedChain(uint256 chainId, bool supported) internal {
        _supportedChains[chainId] = supported;
        emit ChainSupportUpdated(chainId, supported);
    }
    
    /**
     * @dev Create bridge request
     */
    function _createBridgeRequest(
        uint256 tokenId,
        address owner,
        uint256 destinationChainId
    ) internal returns (bytes32 requestId) {
        require(_supportedChains[destinationChainId], "Chain not supported");
        require(!_lockedTokens[tokenId], "Token already locked");
        
        requestId = keccak256(abi.encodePacked(
            tokenId,
            owner,
            destinationChainId,
            block.timestamp,
            block.number
        ));
        
        _bridgeRequests[requestId] = BridgeRequest({
            tokenId: tokenId,
            owner: owner,
            destinationChainId: destinationChainId,
            bridgeHash: requestId,
            timestamp: block.timestamp,
            processed: false
        });
        
        _lockedTokens[tokenId] = true;
        
        emit BridgeRequestCreated(requestId, tokenId, owner, destinationChainId);
        emit TokenLocked(tokenId, destinationChainId);
        
        return requestId;
    }
    
    /**
     * @dev Process bridge request (operator only)
     */
    function _processBridgeRequest(bytes32 requestId, bool success) internal {
        require(msg.sender == _bridgeOperator, "Not bridge operator");
        
        BridgeRequest storage request = _bridgeRequests[requestId];
        require(!request.processed, "Already processed");
        
        request.processed = true;
        
        if (!success) {
            // Unlock token on failure
            _lockedTokens[request.tokenId] = false;
            emit TokenUnlocked(request.tokenId);
        }
        
        emit BridgeRequestProcessed(requestId, success);
    }
    
    /**
     * @dev Check if token is locked for bridging
     */
    function isTokenLocked(uint256 tokenId) public view returns (bool) {
        return _lockedTokens[tokenId];
    }
    
    /**
     * @dev Check if chain is supported
     */
    function isChainSupported(uint256 chainId) public view returns (bool) {
        return _supportedChains[chainId];
    }
    
    /**
     * @dev Get bridge request
     */
    function getBridgeRequest(bytes32 requestId) public view returns (
        uint256 tokenId,
        address owner,
        uint256 destinationChainId,
        uint256 timestamp,
        bool processed
    ) {
        BridgeRequest memory request = _bridgeRequests[requestId];
        return (
            request.tokenId,
            request.owner,
            request.destinationChainId,
            request.timestamp,
            request.processed
        );
    }
    
    /**
     * @dev Get bridge operator
     */
    function getBridgeOperator() public view returns (address) {
        return _bridgeOperator;
    }
    
    /**
     * @dev Modifier for locked token transfers
     */
    modifier notLocked(uint256 tokenId) {
        require(!_lockedTokens[tokenId], "Token locked for bridging");
        _;
    }
}
