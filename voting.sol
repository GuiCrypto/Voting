// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.18;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


contract Voting is Ownable {


    address[] votersIdArray;
    mapping(address => Voter) voters;
    uint public nbProposal;
    mapping (uint => Proposal) public proposals;

    uint nb_voting;

    struct Voter {
        bool isRegistered;
        bool hasVoted;
        uint votedProposalId;
    }

    struct Proposal {
        string description;
        uint voteCount;
    }

    enum WorkflowStatus {
        RegisteringVoters,
        ProposalsRegistrationStarted,
        ProposalsRegistrationEnded,
        VotingSessionStarted,
        VotingSessionEnded,
        VotesTallied
    }



    event VoterRegistered(address voterAddress); 
    event WorkflowStatusChange(WorkflowStatus previousStatus, WorkflowStatus newStatus);
    event ProposalRegistered(uint proposalId);
    event Voted (address voter, uint proposalId);

    modifier onlyVoter() {
        require(voters[msg.sender].isRegistered, "only registered voter can summit proposal");
        _;
    }
    /*
    // QUestion
    Est ce qu'un votant peut soumettre plusieurs propositions ? (pour le moment oui)
    
    // BONUS
    function voterAdd() onlyOwner; // interdit pendant la phase de vote
    function voterRevoke() onlyOwner; // interdit pendant la phase de vote
    function delegateMyVote();  // interdit pendant la phase de vote


    */

    function addVoter(address _address) public onlyOwner {
        votersIdArray.push(_address);
        voters[_address] = Voter(true, false, 0);
    }

    function addVotersArray(address[] calldata _addArray) external onlyOwner {
        for (uint i = 0; i < _addArray.length; i++) {
            addVoter(_addArray[i]);
        }

    }

    function addProposal(string calldata _description) public onlyVoter {
        nbProposal ++;
        proposals[nbProposal] = Proposal(_description, 0); 
    }


    function getProposalByIndex(uint _proposalId) public view onlyVoter returns(Proposal memory) {
        require(_proposalId > 0 && _proposalId < nbProposal+1, string.concat("the identifier of Proposal does not exist. Please indicate a value between 1 and ", Strings.toString(nbProposal)));
        return proposals[_proposalId];
    }

    function vote(uint _proposalId) external onlyVoter {
        require(voters[msg.sender].hasVoted == false, "you have already voted");
        require(_proposalId > 0 && _proposalId < nbProposal+1, string.concat("the identifier of Proposal does not exist. Please indicate a value between 1 and ", Strings.toString(nbProposal)));
        uint beforeVoteProposalCount = proposals[_proposalId].voteCount;
        voters[msg.sender].votedProposalId = _proposalId;
        proposals[_proposalId].voteCount ++;
        nb_voting ++;
        voters[msg.sender].hasVoted = true;
        assert(beforeVoteProposalCount + 1 == proposals[_proposalId].voteCount);
        assert(voters[msg.sender].hasVoted);
    }


    function getProposalWinner() external view onlyVoter returns(uint) {
        uint maxVote;
        uint maxVoteProposalId;
        bool equality;
        for (uint proposalId = 0; proposalId < nbProposal; proposalId++) {
            if (proposals[proposalId].voteCount > maxVote) {
                maxVote = proposals[proposalId].voteCount;
                maxVoteProposalId = proposalId;
                if (equality == true) {
                    equality = false;
                }
            }
            else if (proposals[proposalId].voteCount == maxVote) {
                equality = true;
            }
        }
        return maxVoteProposalId;
    }
}