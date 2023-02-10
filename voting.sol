// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.18;

import "@openzeppelin/contracts/access/Ownable.sol";


contract Voting is Ownable {


    address[] votersIdArray;
    mapping(address => Voter) voters;

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




    /*
    // BONUS
    function voterAdd() onlyOwner; // interdit pendant la phase de vote
    function voterRevoke() onlyOwner; // interdit pendant la phase de vote
    function delegateMyVote();  // interdit pendant la phase de vote
    */

    function addVoter(address _address) private onlyOwner {
        votersIdArray.push(_address);
        voters[_address] = Voter(true, false, 0);
    }

    function addVotersArray(address[] calldata _addArray) external onlyOwner{
        for (uint i = 0; i < _addArray.length; i++) {
            addVoter(_addArray[i]);
        }

    }
}