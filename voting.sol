// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.18;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

/**
 * @dev this contract is a voting system. For more details on how it works please 
 * refer to readme.md
 *
 * Basically there is 2 roles :
 *  Owner: who is the administrator of the smart contract (and not necessarily a voter) who validates and passes the voting steps.
 *  Voter : who is the citizen. He can submit proposals to the vote, vote, check that the vote is not rigged.
 * 
 * depencies : 
 *     - Ownable :  from openzeppelin
 *     - Strings :  from openzeppelin
 */
contract Voting is Ownable {

    mapping(address => Voter) voters;                // Assigns to an address a Voter struct.
    address[] votersArray;                           // Array of voter address.
    uint proposalId;                                 // Proposal Identifier.
    mapping (uint => Proposal) proposals;            // Assign to a ProposalId a Proposal struct.
    mapping(uint => address[]) votersDistribution;   // Assign to a ProposalId a array of address he addresses that voted for it.
    WorkflowStatus voteStatus;                       // Assign to voteStatus WorkflowStatus enum.
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
    event VoterRemoved(address voterAddress);
    event WorkflowStatusChange(WorkflowStatus previousStatus, WorkflowStatus newStatus);
    event ProposalRegistered(uint proposalId);
    event Voted (address voter, uint proposalId);

    constructor() {
        voteStatus = WorkflowStatus.RegisteringVoters;     // Initialize voteStatus to RegisteringVoters (voteStatus index 0).
        proposals[proposalId] = Proposal("Blank vote", 0); // Initialize proposals with blank vote 
    }

    /**
     * @dev Throws to check is msg.sender is an Owner or a Voter.
     */
    modifier onlyOwnerOrVoter()  {
        _checkOwnerOrVoter();
        _;
    }

    /**
     * @dev Throws to check is msg.sender is a Voter.
     */  
    modifier onlyVoter() {
        _checkVoter();
        _;
    }

    /**
     * @dev Throws before and after vote function.
     * before : 
     *          - check if Voter as not already voted
     *          - check if proposalId is valid
     *
     * after : 
     *         - check if Proposal has received a new vote
     *         - check that the vote has been counted on the Voter's struct
     *         - check that votersDistribution variable has been filled.
     */  
    modifier voteValidator(uint _proposalId) {
        _checkAlreadyVote();
        _checkProposalId(_proposalId);
        uint beforeVoteProposalCount = proposals[_proposalId].voteCount;
        _;
        assert(beforeVoteProposalCount + 1 == proposals[_proposalId].voteCount);
        assert(voters[msg.sender].hasVoted);
        assert(votersDistribution[_proposalId].length == beforeVoteProposalCount + 1);
        emit Voted(msg.sender, _proposalId);
    }

    /**
     * @dev Throws to check if voteStatus if superior than required _voteStatusValue.
     */  
    modifier voteStatusSuperiorThan(uint _voteStatusValue) {
        _checkVoteStatusSuperiorThan(_voteStatusValue);
        _;
    }

    /**
     * @dev Throws to check if voteStatus if equal than required _voteStatusValue.
     */  
    modifier voteStatusEqualTo(uint _voteStatusValue) {
        _checkVoteStatusEqualTo(_voteStatusValue);
        _;
    }

    /**
     * @dev Throws to check if a changing of voteStatus is possible and emit an event if so. 
     */  
    modifier voteStatusVerifier {
        _checkNextVoteStatus();
        WorkflowStatus previousStatus = voteStatus;
        _;
        emit WorkflowStatusChange(previousStatus, voteStatus);
    }

    /**
     * @dev Verifiy if the initiator of the function is a Voter or an Owner.
     */  
    function _checkOwnerOrVoter() internal view virtual {
        require(voters[msg.sender].isRegistered || msg.sender == owner(), "only owner of this contract and voters can access to this function.");
    }

    /**
     * @dev Verifiy if the initiator (msg.sender) of the function is a Voter.
     */  
    function _checkVoter()  internal view virtual {
        require(voters[msg.sender].isRegistered, "only registered voter can make this action.");

    }

    /**
     * @dev Verifiy if the initiator  (msg.sender) of the function has already voted.
     */  
    function _checkAlreadyVote() internal view virtual {
        require(voters[msg.sender].hasVoted == false, "you have already voted.");
    }

    /**
     * @dev Verifiy if the initiator (msg.sender) of the function has already voted.
     */  
    function _checkProposalId(uint _proposalId) internal view virtual {
        require(_proposalId < proposalId+1, string.concat("the identifier of Proposal does not exist. Please indicate a value between 1 and ", Strings.toString(proposalId)));
    }

    /**
     * @dev Verifiy if voteStatus enum is superior than required _voteStatusValue.
     */  
    function _checkVoteStatusSuperiorThan(uint _voteStatusValue) internal view virtual {
        require(uint(voteStatus) > _voteStatusValue, string.concat("the voteStatus is currently to ", Strings.toString(uint(voteStatus)), " this action is possible only for a vote status superior than ", Strings.toString(_voteStatusValue)));
    }

    /**
     * @dev Verifiy if voteStatus enum is equal than required _voteStatusValue.
     */
    function  _checkVoteStatusEqualTo(uint _voteStatusValue) internal view virtual {      
        require(uint(voteStatus) == _voteStatusValue, string.concat("the voteStatus is currently to ", Strings.toString(uint(voteStatus)), " this action is possible only for a vote status equal to ", Strings.toString(_voteStatusValue)));
    }

    /**
     * @dev Verifiy if it is possible to upper voteStatus enum.
     */
    function _checkNextVoteStatus() internal view virtual {
        if  (uint(voteStatus)==0) {
            require(votersArray.length>0, "you cannot proceed to ProposalsRegistrationStarted (voteStatus 1) there is no voter registered");
        }
        else if (uint(voteStatus)==1) {
            require(proposalId> 1, "you cannot proceed to ProposalsRegistrationEnded (voteStatus 2) there is no or just one proposal submitted");
        }
        else if (uint(voteStatus)==3) {
            require(nbVoting>0, "you cannot proceed to VotingSessionEnded (voteStatus 4) no body have already vote");
        }
        else if (uint(voteStatus)==5) {
            require(uint(voteStatus) < 5, "You have already reached the final stage of voting : VotesTallied (voteStatus 5)");
        }
    }

    /**
     * @dev return the voteStatus index.
     *
     */
    function getVoteStatus() external view returns(WorkflowStatus) {
        return voteStatus;
    }

    /**
     * @dev Proceed to next voteStatus index. 
     *
     * Restriction(s) : 
     *  - only accessible to Owner.
     */
    function nextVoteStatus() external onlyOwner voteStatusVerifier {
        voteStatus = WorkflowStatus(uint(voteStatus) + 1);
    }

    /**
     * @dev add new Voter to voters mapping and votersArray. 
     *
     * Restriction(s) :  
     *  - only accessible to Owner.
     *  - only executed when voteStatus is equal to 0.
     */
    function addVoter(address _address) public onlyOwner voteStatusEqualTo(0) {
        voters[_address] = Voter(true, false, 0);
        votersArray.push(_address);
        emit VoterRegistered(_address);
    }

    /**
     * @dev add new Voter to voters mapping and votersArray. 
     *
     * Restriction(s) :
     *  - only accessible to Owner.
     *  - only executed when voteStatus is equal to 0.
     */
    function addVotersArray(address[] calldata _addArray) external onlyOwner voteStatusEqualTo(0) {
        for (uint i = 0; i < _addArray.length; i++) {
            addVoter(_addArray[i]);
        }

    }

    /**
     * @dev remove Voter to voters mapping and votersArray.
     *
     * Restriction(s) :
     *  - only accessible to Owner.
     *  - only executed when voteStatus is equal to 0.
     */
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
        emit VoterRemoved(_address);
    }

    /**
     * @dev returns the list of voters. 
     *
     * Restriction(s) : 
     * - only executed when voteStatus is superior than 0.
     */
    function getVotersArray() external view voteStatusSuperiorThan(0) returns(address[] memory) {
        return votersArray;
    }

    /**
     * @dev this function allow Voter to add a Proposal.
     * 
     * Restriction(s) : 
     * - only accessible to Voter 
     * - only executed when voteStatus is equal to 1.
     */
    function addProposal(string calldata _description) external onlyVoter voteStatusEqualTo(1) {
        proposalId ++;
        proposals[proposalId] = Proposal(_description, 0); 
        emit ProposalRegistered(proposalId);
    }

    /**
     * @dev returns the proposal description that refere to required _proposalId.
     *
     * Restriction(s) : 
     * - only executed when voteStatus is superior than 0.
     */
    function getProposalDescription(uint _proposalId) public view voteStatusSuperiorThan(0) returns(string memory) {
        _checkProposalId(_proposalId);
        return proposals[_proposalId].description;
    }

    /**
     * @dev returns the number of proposals.
     *
     * Restriction(s) : 
     * - only executed when voteStatus is superior than 0.
     */
    function howManyProposals() external view voteStatusSuperiorThan(0) returns(uint) {
        return proposalId;
    }

    /**
     * @dev this function allow Voter to vote.
     *
     * To be valid :
     * - the Voter must not have voted yet.
     * - the Voter boolean hasVoted takes true value.
     * - the voted proposal counter is incremented by 1.
     * - the nbVoting variable is incremented by 1.
     * 
     * Restriction(s) : 
     * - only executed when voteStatus is equal to 3.
     */
    function vote(uint _proposalId) external onlyVoter voteValidator(_proposalId) voteStatusEqualTo(3) {
        voters[msg.sender].votedProposalId = _proposalId;
        proposals[_proposalId].voteCount ++;
        votersDistribution[_proposalId].push(msg.sender);
        nbVoting ++;
        voters[msg.sender].hasVoted = true;
    }

    /**
     * @dev Return true if the Voter has voted, false if not.
     * 
     * Restriction(s) : 
     * - only accessible to Voter
     * - only executed when voteStatus is superior than 2.
     */
    function didIVote() external view onlyVoter voteStatusSuperiorThan(2) returns(bool) {
        return voters[msg.sender].hasVoted;
    }

    /**
     * @dev Return the proposal number voted by the Voter.
     * 
     * Restriction(s) : 
     * - only accessible to Voter
     * - only executed when voteStatus is superior than 2.
     */
    function whichProposalDidIVote() external view onlyVoter voteStatusSuperiorThan(2) returns(uint) {
        require(voters[msg.sender].hasVoted, "you did not vote");
        return voters[msg.sender].votedProposalId;

    }
    
    /**
     * @dev Return the voting participation (The number of Voters who voted).
     * 
     * Restriction(s) : 
     * - only executed when voteStatus is superior than 2.
     */
    function voteParticipation() external view voteStatusSuperiorThan(2) returns(uint) {
        return nbVoting;
    }


    /**
     * @dev Return the winning proposal
     *
     * Rules :
     *  - the winning proposal is the one with the most votes
     *  - if equality between the proposals with the most votes this function return zero. 
     * 
     * Restriction(s) : 
     * - only executed when voteStatus is equal to 5.
     */
    function getWinner() external view voteStatusEqualTo(5) returns(uint) {
        uint maxVote;
        uint maxVoteProposalId;
        bool equality;
        for (uint _proposalId = 1; _proposalId < proposalId + 1; _proposalId++) {
            if (proposals[_proposalId].voteCount > maxVote) {
                maxVote = proposals[_proposalId].voteCount;
                maxVoteProposalId = _proposalId;
                if (equality == true) {
                    equality = false;
                }
            }
            else if (proposals[_proposalId].voteCount == maxVote) {
                equality = true;
            }
            if (equality) {
                maxVoteProposalId = 0; // no winner
            }
        }
        return maxVoteProposalId;
    }

    /**
     * @dev Return the vote count of a proposal
     *
     * Restriction(s) : 
     * - only executed when voteStatus is equal to 5.
     */
    function howManyVoteForProposal(uint _proposalId) external view voteStatusEqualTo(5) returns(uint)  {
        _checkProposalId(_proposalId);
        return proposals[_proposalId].voteCount;
    }

    /**
     * @dev Return the list of address that voted required _proposalId.
     *
     * Restriction(s) : 
     * - only accessible to Owner or Voter 
     * - only executed when voteStatus is equal to 5.
     */
    function whoVoteForProposalId(uint _proposalId) external view onlyOwnerOrVoter voteStatusEqualTo(5) returns(address[] memory) {
        _checkProposalId(_proposalId);
        return votersDistribution[_proposalId];
    }

}