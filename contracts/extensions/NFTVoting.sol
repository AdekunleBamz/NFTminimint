// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title NFTVoting
 * @dev Extension for token-weighted governance voting
 */
abstract contract NFTVoting {
    
    struct Proposal {
        string description;
        uint256 forVotes;
        uint256 againstVotes;
        uint256 startTime;
        uint256 endTime;
        bool executed;
        mapping(uint256 => bool) hasVoted;
    }
    
    uint256 private _proposalCount;
    mapping(uint256 => Proposal) private _proposals;
    uint256 private _votingPeriod = 3 days;
    uint256 private _quorum = 10; // 10% quorum
    
    event ProposalCreated(uint256 indexed proposalId, string description, uint256 endTime);
    event VoteCast(uint256 indexed proposalId, uint256 indexed tokenId, bool support);
    event ProposalExecuted(uint256 indexed proposalId);
    event VotingPeriodUpdated(uint256 oldPeriod, uint256 newPeriod);
    
    /**
     * @dev Create a new proposal
     */
    function _createProposal(string memory description) internal returns (uint256) {
        uint256 proposalId = ++_proposalCount;
        Proposal storage proposal = _proposals[proposalId];
        
        proposal.description = description;
        proposal.startTime = block.timestamp;
        proposal.endTime = block.timestamp + _votingPeriod;
        
        emit ProposalCreated(proposalId, description, proposal.endTime);
        return proposalId;
    }
    
    /**
     * @dev Cast vote with a token
     */
    function _castVote(uint256 proposalId, uint256 tokenId, bool support) internal {
        Proposal storage proposal = _proposals[proposalId];
        
        require(block.timestamp >= proposal.startTime, "Voting not started");
        require(block.timestamp <= proposal.endTime, "Voting ended");
        require(!proposal.hasVoted[tokenId], "Already voted with token");
        
        proposal.hasVoted[tokenId] = true;
        
        if (support) {
            proposal.forVotes++;
        } else {
            proposal.againstVotes++;
        }
        
        emit VoteCast(proposalId, tokenId, support);
    }
    
    /**
     * @dev Mark proposal as executed
     */
    function _executeProposal(uint256 proposalId) internal {
        Proposal storage proposal = _proposals[proposalId];
        require(!proposal.executed, "Already executed");
        require(block.timestamp > proposal.endTime, "Voting not ended");
        
        proposal.executed = true;
        emit ProposalExecuted(proposalId);
    }
    
    /**
     * @dev Set voting period
     */
    function _setVotingPeriod(uint256 period) internal {
        uint256 oldPeriod = _votingPeriod;
        _votingPeriod = period;
        emit VotingPeriodUpdated(oldPeriod, period);
    }
    
    /**
     * @dev Get proposal info
     */
    function getProposal(uint256 proposalId) public view returns (
        string memory description,
        uint256 forVotes,
        uint256 againstVotes,
        uint256 startTime,
        uint256 endTime,
        bool executed
    ) {
        Proposal storage proposal = _proposals[proposalId];
        return (
            proposal.description,
            proposal.forVotes,
            proposal.againstVotes,
            proposal.startTime,
            proposal.endTime,
            proposal.executed
        );
    }
    
    /**
     * @dev Check if token has voted on proposal
     */
    function hasVoted(uint256 proposalId, uint256 tokenId) public view returns (bool) {
        return _proposals[proposalId].hasVoted[tokenId];
    }
    
    /**
     * @dev Get total proposal count
     */
    function proposalCount() public view returns (uint256) {
        return _proposalCount;
    }
    
    /**
     * @dev Get current voting period
     */
    function votingPeriod() public view returns (uint256) {
        return _votingPeriod;
    }
}
