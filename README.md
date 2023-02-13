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

The voting system has several checks in place to ensure the validity of voting, such as checking if the voter has already voted and if the `proposalId` is valid, and also updates the `voters` and `proposals` informations after a vote has been cast.

## The stages of the vote

Voting takes place in six distinct stages (save in variable `voteStatus`):

1. `RegisteringVoters` : the `Owner` can register `Voter`.
2. `ProposalsRegistrationStarted` : the `Voter` can submit a Proposal to vote.
3. `ProposalsRegistrationEnded` :  the `Owner` stops the period of submitting `Proposal` : by design at least two proposals must be filled to close registration.
4. `VotingSessionStarted` : the `Voter` can vote
5. `VotingSessionEnded` : the voting session is closed.
6. `VotesTallied` : the votes are counted and the winning proposal is declared (if there is one).

It is the `Owner` of the contract who passes each step (using `nextVoteStatus` function). By design it is impossible to go back.

## Roles

There are two main roles that can interact with the contract: `Owner` and `Voter`. However, some functions of the smart contract remain accessible from the outside to ensure the smooth running and the sincerity of the vote.

### Owner

The `Owner` is the administrator of the smart contract and can validate and pass the voting steps (detailed in the previous section).

- The `Owner` can add and remove a `Voter`.
- The `Owner` is not necessarily a `Voter` : he can add himself in the list of voters if he wishes.

The functions that are reserved for `Owner` are : 
* `addVoter` : add a new `Voter` to voter list (`votersArray`).
* `addVoters` : add an array of `Voter`.
* `removeVoter`: delete a `Voter` address to `votersArray`.
* `nextVoteStatus` : change stage of vote (next enum in  `voteStatus`)
* `transferOwnership` : transfer to another ethereum address the `Owner` role.
* `renonceOwnership` : transfer the `Owner` role to ethereum address 0. The voting process is frozen : a new vote must be realised.


### Voter

The Voter is the citizen who can submit proposals, vote, and check if the vote is not rigged. 
Functions that are reserved for `Voter` are : 
* `addProposal` : add a proposal to vote.
* `vote`: execute vote. 
* `didIVote` : returns a boolean to remember if the `Voter` voted or not.
* `whichProposalDidIVote` : returns the `proposalId` for which the `Voter` voted.

> *Blank vote* is allowed. To do that `Voter` must vote for `proposalId` :  0.

### external users

For reasons of transparency, external users can access certain functions of the smart contract, essentially to ensure the vote sincerity while maintaining privacy.

Everybody can access the following variables and functions: 
    `owner` :  the address of Owner.
    `getVotersArray`: the Voter's address list.
    `howManyProposal` : the number of proposal.
    `getVoteStatus`: get stage of the vote.
    `getProposalDescription` : the description of proposal.
    `voteParticipation`: the number of `Voter` that voted.
    `howManyVoteForProposal`:  the number of vote for a proposalId.
    `getWinner` : the winning `proposalId`.


`getVotersArray`, `voteParticipation`, `howManyVoteForProposal`, `getWinner` can be compared with `events` during vote to ensure the fairness of the vote.

## table of functions and access restrictions

     
| function name            | associated role(s) | vote status step                                   |
|--------------------------|--------------------|----------------------------------------------------|
| `addProposal`            | `Voter`            | ProposalsRegistrationStarted (index : 1)           |
| `addVoter`               | `Owner`            | RegisteringVoters (index : 0)                      |
| `addVoters`              | `Owner`            | RegisteringVoters (index : 0)                      |
| `NextVoteStatus`         | `Owner`            | no restriction                                     |
| `removeVoter`            | `Owner`            | RegisteringVoters (index : 0)                      |
| `renounceOwnership`      | `Owner`            | no restriction                                     |
| `transfertOwner`         | `Owner`            | no restriction                                     |
| `vote`                   | `Voter`            | VotingSessionStarted (index : 3)                   |
| `didIVote`               | `Voter`            | **after** ProposalsRegistrationEnded (index : > 2) |
| `getProposalDescription` | no restriction     | **after** RegisteringVoters (index : > 0)          |
| `getVotersArray`         | no restriction     | **after** RegisteringVoters (index : > 0)          |
| `getWinner`              | no restriction     | VotesTallied (index : 5)                           |
| `howManyProposals`       | no restriction     | **after** RegisteringVoters (index : > 0)          |
| `howManyVoteForProposal` | no restriction     | VotesTallied (index : 5)                           |
| `voteParticipation`      | no restriction     | **after** ProposalsRegistrationEnded (index : > 2) |
| `whichProposalDidIVote`  | `Voter`            | **after** ProposalsRegistrationEnded (index : > 2) |
| `whoVoteForProposalId`   | `Owner` or `Voter` | VotesTallied (index : 5)                           |


## Results

The election winner is given at last step : `VotesTallied` and everybody can acces the result via `getWinner` function. 
This function returns the `proposalId` of winning `Proposal`.

To be the winner a proposal must respect these rules : 
* the winning proposal is the one with the most votes
* if there is an equality between most voted proposals, this function returns 0. 
* blank vote is counted in participation but has no impact on proposal vote count.

Then if the return of `getWinner` function is 0, a new vote must be taken to decide the winner.

