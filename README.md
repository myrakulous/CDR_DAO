# Climate Disaster Relief DAO Contract

This Clarity smart contract establishes a decentralized autonomous organization (DAO) for managing disaster relief funds through transparent, member-driven proposals and voting mechanisms.

## Features

* **DAO Membership**: Only the contract owner can add new DAO members.
* **Treasury Donations**: Public donations in STX increase the DAO treasury balance.
* **Proposal System**: Members can propose fund disbursement with description, recipient, and amount.
* **Voting Mechanism**: Members vote on proposals; passing requires 51% approval.
* **Execution Logic**: Funds are transferred to the recipient if the proposal passes and execution conditions are met.

## Data Structures

* **Proposal Counter**: Tracks number of proposals.
* **Treasury Balance**: Total STX available.
* **Quorum Percentage**: Approval threshold, set to 51%.
* **Proposals Map**: Stores proposal details including vote counts and execution status.
* **Member Votes Map**: Prevents double voting.
* **Members Map**: Tracks authorized voting members.

## Public Functions

* `add-member`: Contract owner adds a new DAO member.
* `donate`: Send STX to the DAO treasury.
* `create-proposal`: Member proposes a fund disbursement.
* `vote`: Members cast yes/no votes on proposals.
* `execute-proposal`: Transfer funds to the recipient if voting passed.

## Read-Only Functions

* `get-proposal`
* `has-voted`
* `is-member`
* `get-treasury-balance`

## Voting & Execution Rules

* Proposal is open for \~10 days (1440 blocks).
* Quorum: 51% of votes must be in favor for approval.
* Execution occurs only after the proposal expires and has not been executed yet.

## Error Handling

Robust error codes ensure:

* Only members can propose or vote.
* No double voting.
* Proposals can't be executed early or multiple times.
* Sufficient funds are available before proposing disbursements.
