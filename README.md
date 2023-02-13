# Voting smart contract

You will find here the documentation to deploy and interact with the Ethereum smart contract `Voting` included in the `voting.sol` file.

## abstract

This smart contract is a voting system that has two roles: Owner and Voter.
The contract uses OpenZeppelin's `Ownable` and `Strings` contracts for its dependencies.

The contract maps an address to a Voter struct that includes information such as if the voter is registered and if they have voted, and assigns the address to an array of voter addresses.
The contract also has a proposal identifier and maps a proposal ID to a Proposal struct that includes the description and vote count. 
The contract also keeps track of the voting status using an enum `WorkflowStatus` and has various events for different actions such as :
* voter registration `VoterRegistered`
* remove voter to voter's list `VoterRemoved`
* change stage of vote `WorkflowStatusChange`
* proposal registration `ProposalRegistered`
* voting. `Voted`

The contract has several functions such as vote(), registerVoter(), and registerProposal(), which are restricted by various access control modifiers that throw errors if the msg.sender is not a Voter or Owner.

The voting system has several checks in place to ensure the validity of voting, such as checking if the voter has already voted and if the proposal ID is valid, and also updates the voter and proposal information after a vote has been cast.

## The stages of the vote

Voting takes place in six distinct stages (save in variable `voteStatus`):

1. `RegisteringVoters` : the `Owner` can registre `Voter`.
2. `ProposalsRegistrationStarted` : the `Voter` can submit a Proposal to vote.
3. `ProposalsRegistrationEnded` :  the `Owner` stop the period of submitting `Proposal`, by design at least two proposals must be filled to close registration.
4. `VotingSessionStarted` : the `Voter` can vote
5. `VotingSessionEnded` : the vote is ending.
6. `VotesTallied` : the votes are counted and the winning proposal is declared (if there is one).

It is the `Owner` of the contract who passes each step (using `nextVoteStatus` function ). By design it is impossible to go back.

## Roles

There are two main roles that can interact with the contract: Owner and Voter. However, some functions of the smart contract remain accessible from the outside to ensure the smooth running and the sincerity of the vote.

### Owner

The Owner is the administrator of the smart contract and can validate and pass the voting steps (detailed in the previous section).

- The Owner can add and remove Voter
- The Owner is not necessarily a voter: he can add himself in the list of voters if he wishes.

The functions that are reserved for him are : 
* `addVoter` : add a new `Voter` to voter list (`votersArray`).
* `addVoters` : add an array of `Voter`.
* `removeVoter`: delete a address to `votersArray`.
* `nextVoteStatus` : change statge of vote (next enum in  `voteStatus`)
* `transferOwnership` : transfert to another ethereum address the `Owner` role.
* `renonceOwnership` : transfert the Owner role to ethereum address 0. The voting process is freeze a new Voting must be realised.


### Voter

the Voter is the citizen who can submit proposals, vote, and check if the vote is not rigged. 
The functions that are reserved for him are : 
* `addProposal` : add a proposal subbmited to vote.
* `vote`: execute vote. 
* `didIVote` : returns a boolean to remember if the `Voter` voted or not.
* `whichProposalDidIVote` : returns the proposalId for which the `Voter` voted.

### external users

For reasons of transparency, external users can access certain functions of the smart contract. Essentially to ensure the sincerity of the vote while maintaining privacy.

Everybody can access the following variables and functions: 
    `owner` :  the address of Owner.
    `getVotersArray`: the Voter's address list.
    `howManyProposal` : the number of proposal.
    `getVoteStatus`: get stage of the vote.
    `getProposalDescription` : the description of proposal.
    `voteParticipation`: the number of Voter that vote.
    `howManyVoteForProposal`:  the number of vote for a proposalId.
    `getWinner` : the winning proposalId.


`getVotersArray`, `voteParticipation`, `howManyVoteForProposal`, `getWinner` can be compare with events during vote to ensure the fairness of the vote.

## table of functions and access restrictions

     
| function name            | role associed  | vote status step                                   |
|--------------------------|----------------|----------------------------------------------------|
| `addProposal`            | Voter          | ProposalsRegistrationStarted (index : 1)           |
| `addVoter`               | Owner          | RegisteringVoters (index : 0)                      |
| `addVoters`              | Owner          | RegisteringVoters (index : 0)                      |
| `NextVoteStatus`         | Owner          | no restriction                                     |
| `removeVoter`            | Owner          | RegisteringVoters (index : 0)                      |
| `renounceOwnership`      | Owner          | no restriction                                     |
| `transfertOwner`         | Owner          | no restriction                                     |
| `vote`                   | Voter          | VotingSessionStarted (index : 3)                   |
| `didIVote`               | Voter          | **after** ProposalsRegistrationEnded (index : > 2) |
| `getProposalDescription` | no restriction | **after** RegisteringVoters (index : > 0)          |
| `getVotersArray`         | no restriction | **after** RegisteringVoters (index : > 0)          |
| `getWinner`              | no restriction | VotesTallied (index : 5)                           |
| `howManyProposals`       | no restriction | **after** RegisteringVoters (index : > 0)          |
| `howManyVoteForProposal` | no restriction | VotesTallied (index : 5)                           |
| `voteParticipation`      | no restriction | **after** ProposalsRegistrationEnded (index : > 2) |
| `whichProposalDidIVote`  | Voter          | **after** ProposalsRegistrationEnded (index : > 2) |
| `whoVoteForProposalId`   | Voter          | VotesTallied (index : 5)                           |


## Results

The election winner is given at last step : `VotesTallied` and everybody can acces to result via `getWinner` function. This function return the `proposalId` who win.

To be the winner a proposal must respect this rules : 
* the winning proposal is the one with the most votes
* if equality between the proposals with the most votes this function return zero. 

Then if the return of `getWinner` function is 0 a new vote must be taken to decide the winners.

