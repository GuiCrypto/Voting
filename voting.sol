// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.18;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


contract Voting is Ownable {

    mapping(address => Voter) voters;
    address[] votersArray;
    mapping(uint => address[]) votersDistribution;
    uint public nbProposal;
    mapping (uint => Proposal) public proposals;

    WorkflowStatus voteStatus;
    uint iVoteStatus;

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

    constructor() {
        voteStatus = WorkflowStatus.RegisteringVoters;
        iVoteStatus = 0;
    }

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

    modifier voteStatusSuperiorThan(uint _voteStatusValue) {
        require(uint(voteStatus) > _voteStatusValue, string.concat("the voteStatus is actualy to ", Strings.toString(uint(voteStatus)), " this action is possible only for a vote status superior than ", Strings.toString(_voteStatusValue)));
        _;
    }

    modifier voteStatusEqualTo(uint _voteStatusValue) {
        require(uint(voteStatus) == _voteStatusValue, string.concat("the voteStatus is actualy to ", Strings.toString(uint(voteStatus)), " this action is possible only for a vote status equal to ", Strings.toString(_voteStatusValue)));
        _;
    }

    modifier voteStatusVerifier {
        _checkNextVoteStatus();
        _;
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

    function _checkProposalId(uint _proposalId) internal view virtual {
        require(_proposalId > 0 && _proposalId < nbProposal+1, string.concat("the identifier of Proposal does not exist. Please indicate a value between 1 and ", Strings.toString(nbProposal)));
    }

    function _checkNextVoteStatus() internal view virtual {
        if  (uint(voteStatus)==0) {
            require(votersArray.length>0, "you cannot proceed to ProposalsRegistrationStarted (voteStatus 1) there is no voter registered");
        }
        else if (uint(voteStatus)==1) {
            require(nbProposal> 0, "you cannot proceed to ProposalsRegistrationEnded (voteStatus 2) there is no proposal submitted");
        }
        else if (uint(voteStatus)==3) {
            require(nbVoting>0, "you cannot proceed to VotingSessionEnded (voteStatus 4) no body have already vote");
        }
        else if (uint(voteStatus)==5) {
            require(uint(voteStatus) < 5, "You have already reached the final stage of voting : VotesTallied (voteStatus 5)");
        }
    }

    function getVoteStatus() external view onlyOwnerOrVoter returns(WorkflowStatus) {
        return voteStatus;
    }

    function nextVoteStatus() external onlyOwner voteStatusVerifier {
        voteStatus = WorkflowStatus(uint(voteStatus) + 1);
    }

    function addVoter(address _address) public onlyOwner voteStatusEqualTo(0) {
        voters[_address] = Voter(true, false, 0);
        votersArray.push(_address);
    }

    function addVotersArray(address[] calldata _addArray) external onlyOwner voteStatusEqualTo(0) {
        for (uint i = 0; i < _addArray.length; i++) {
            addVoter(_addArray[i]);
        }

    }

    function removeVoter(address _address) public onlyOwner voteStatusEqualTo(0) {
        require(voters[_address].isRegistered, "input address is not registered as a voter");
        voters[_address] = Voter(false, false, 0);
        address[] memory newVotersArray = new address[](votersArray.length - 1);
        uint j;
        for (uint i=0; i < votersArray.length; i++) {
            if (votersArray[i] != _address) {
                newVotersArray[j] = votersArray[i];
                j++;
            }
        }
        votersArray = newVotersArray;
    }

    function addProposal(string calldata _description) public onlyVoter voteStatusEqualTo(1) {
        nbProposal ++;
        proposals[nbProposal] = Proposal(_description, 0); 
    }


    function getProposalByIndex(uint _proposalId) public view onlyVoter voteStatusSuperiorThan(0) returns(Proposal memory) {
        _checkProposalId(_proposalId);
        return proposals[_proposalId];
    }

    function vote(uint _proposalId) external onlyVoter voteValidator(_proposalId) voteStatusEqualTo(3) {
        voters[msg.sender].votedProposalId = _proposalId;
        proposals[_proposalId].voteCount ++;
        votersDistribution[_proposalId].push(msg.sender);
        nbVoting ++;
        voters[msg.sender].hasVoted = true;
    }

    function didIVote() external view onlyVoter voteStatusSuperiorThan(2) returns(bool) {
        return voters[msg.sender].hasVoted;
    }

    function whichProposalDidIVote() external view onlyVoter voteStatusSuperiorThan(2) returns(uint) {
        require(voters[msg.sender].hasVoted, "you did not vote");
        return voters[msg.sender].votedProposalId;

    }
    
    function voteParticipation() external view onlyOwnerOrVoter voteStatusSuperiorThan(2) returns(uint) {
        return nbVoting;
    }

    function getProposalWinner() external view onlyOwnerOrVoter voteStatusEqualTo(5) returns(uint) {
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

    function whoVoteForProposalId(uint _proposalId) external view onlyOwnerOrVoter voteStatusEqualTo(5) returns(address[] memory) {
        _checkProposalId(_proposalId);
        return votersDistribution[_proposalId];
    }

}