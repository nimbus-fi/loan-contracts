// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./CommunityUnion.sol";

contract Governance is Ownable {
    CommunityUnion public communityUnion;
    
    struct Proposal {
        string description;
        uint256 forVotes;
        uint256 againstVotes;
        mapping(address => bool) hasVoted;
        bool executed;
        uint256 endTime;
    }
    
    Proposal[] public proposals;
    uint256 public constant VOTING_PERIOD = 3 days;
    
    event ProposalCreated(uint256 proposalId, string description);
    event Voted(uint256 proposalId, address voter, bool support);
    event ProposalExecuted(uint256 proposalId);
    
    constructor(address initialOwner, address _communityUnionAddress) Ownable( initialOwner) {
        communityUnion = CommunityUnion(_communityUnionAddress);
    }
    
    function createProposal(string memory description) external {
        require(communityUnion.isMember(msg.sender), "Not a member");
        Proposal storage newProposal = proposals.push();
        newProposal.description = description;
        newProposal.endTime = block.timestamp + VOTING_PERIOD;
        emit ProposalCreated(proposals.length - 1, description);
    }
    
    function vote(uint256 proposalId, bool support) external {
        require(communityUnion.isMember(msg.sender), "Not a member");
        Proposal storage proposal = proposals[proposalId];
        require(block.timestamp < proposal.endTime, "Voting period ended");
        require(!proposal.hasVoted[msg.sender], "Already voted");
        
        if (support) {
            proposal.forVotes += communityUnion.getMemberBalance(msg.sender);
        } else {
            proposal.againstVotes += communityUnion.getMemberBalance(msg.sender);
        }
        
        proposal.hasVoted[msg.sender] = true;
        emit Voted(proposalId, msg.sender, support);
    }
    
    function executeProposal(uint256 proposalId) external onlyOwner {
        Proposal storage proposal = proposals[proposalId];
        require(block.timestamp >= proposal.endTime, "Voting period not ended");
        require(!proposal.executed, "Proposal already executed");
        
        if (proposal.forVotes > proposal.againstVotes) {
            proposal.executed = true;
            emit ProposalExecuted(proposalId);
            // Implement the logic to execute the proposal
        }
    }
}