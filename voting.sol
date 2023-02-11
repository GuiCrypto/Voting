// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.18;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


contract Voting is Ownable {

    mapping(address => Voter) voters;
    mapping(uint => address[]) votersDistribution;
    uint public nbProposal;
    mapping (uint => Proposal) public proposals;

    uint nbVoting;

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

    modifier onlyOwnerOrVoter()  {
        _checkOwnerOrVoter();
        _;
    }
        
    modifier onlyVoter() {
        _checkVoter();
        _;
    }

    modifier voteValidator(uint _proposalId) {
        _checkAlreadyVote();
        _checkProposalId(_proposalId);
        uint beforeVoteProposalCount = proposals[_proposalId].voteCount;
        _;
        assert(beforeVoteProposalCount + 1 == proposals[_proposalId].voteCount);
        assert(voters[msg.sender].hasVoted);
        assert(votersDistribution[_proposalId].length == beforeVoteProposalCount + 1);
    }

    function _checkOwnerOrVoter() internal view virtual {
        require(voters[msg.sender].isRegistered || msg.sender == owner(), "only owner of this contract and voters can access to this function.");
    }

    function _checkVoter()  internal view virtual {
        require(voters[msg.sender].isRegistered, "only registered voter can summit proposal.");

    }

    function _checkAlreadyVote() internal view virtual {
        require(voters[msg.sender].hasVoted == false, "you have already voted");
    }

    function _checkProposalId(uint _proposalId) internal view {
        require(_proposalId > 0 && _proposalId < nbProposal+1, string.concat("the identifier of Proposal does not exist. Please indicate a value between 1 and ", Strings.toString(nbProposal)));
    }

    function addVoter(address _address) public onlyOwner {
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
        _checkProposalId(_proposalId);
        return proposals[_proposalId];
    }

    function vote(uint _proposalId) external onlyVoter voteValidator(_proposalId) {
        voters[msg.sender].votedProposalId = _proposalId;
        proposals[_proposalId].voteCount ++;
        votersDistribution[_proposalId].push(msg.sender);
        nbVoting ++;
        voters[msg.sender].hasVoted = true;
    }

    function didIVote() external view onlyVoter returns(bool) {
        return voters[msg.sender].hasVoted;
    }

    function whichProposalDidIVote() external view onlyVoter returns(uint) {
        require(voters[msg.sender].hasVoted, "you did not vote");
        return voters[msg.sender].votedProposalId;

    }
    
    function voteParticipation() external view onlyOwnerOrVoter returns(uint) {
        return nbVoting;
    }

    function getProposalWinner() external view onlyOwnerOrVoter returns(uint) {
        uint maxVote;
        uint maxVoteProposalId;
        bool equality;
        for (uint proposalId = 1; proposalId < nbProposal + 1; proposalId++) {
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
            if (equality) {
                maxVoteProposalId = 0; // no winner
            }
        }
        return maxVoteProposalId;
    }

    function whoVoteForProposalId(uint _proposalId) external view onlyOwnerOrVoter returns(address[] memory) {
        _checkProposalId(_proposalId);
        return votersDistribution[_proposalId];
    }

}