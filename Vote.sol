//// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";

contract Voting is Ownable {
    enum WorkflowStatus {
        RegisteringVoters,
        ProposalsRegistrationStarted,
        ProposalsRegistrationEnded,
        VotingSessionStarted,
        VotingSessionEnded,
        VotesTallied
    }

    WorkflowStatus public workflowStatus;

    struct Voter {
        bool isRegistered;
        bool hasVoted;
        uint256 votedProposalId;
    }

    struct Proposal {
        string description;
        uint256 voteCount;
    }

    Proposal[] public proposals;

    event VoterRegistered(address voterAddress);
    event WorkflowStatusChange(
        WorkflowStatus previousStatus,
        WorkflowStatus newStatus
    );
    event ProposalRegistered(uint256 proposalId);
    event Voted(address voter, uint256 proposalId);

    mapping(address => Voter) public votants;
    mapping(address => bool) private whitelist;

    modifier checkRegistering() {
        require(whitelist[msg.sender] == true, "you are not authorized");
        _;
    }

    modifier checkVote() {
        require(
            votants[msg.sender].isRegistered =
                true &&
                !votants[msg.sender].hasVoted &&
                workflowStatus == WorkflowStatus.VotingSessionStarted &&
                workflowStatus != WorkflowStatus.VotingSessionEnded,
            "Tu ne peut pas voter"
        );
        _;
    }

    constructor() {
        changeStatus();
    }

    function changeStatus() public onlyOwner {
        adminWhitelist(0x78731D3Ca6b7E34aC0F824c42a7cC18A495cabaB);
        workflowStatus = WorkflowStatus.ProposalsRegistrationStarted;
        emit WorkflowStatusChange(WorkflowStatus(0), WorkflowStatus(1));
    }

    function getWorkflowSatus() public view returns (WorkflowStatus) {
        return workflowStatus;
    }

    function setWorkflowStatus(WorkflowStatus _workflowStatus)
        public
        onlyOwner
    {
        workflowStatus = _workflowStatus;
        emit WorkflowStatusChange(
            WorkflowStatus(workflowStatus),
            WorkflowStatus(_workflowStatus)
        );
    }

    function adminWhitelist(address _voterAddress) public onlyOwner {
        require(
            workflowStatus == WorkflowStatus.RegisteringVoters ||
                workflowStatus == WorkflowStatus.ProposalsRegistrationStarted
        );
        require(
            !whitelist[_voterAddress],
            "This address is already whitelisted !"
        );
        whitelist[_voterAddress] = true;
    }

    function proposalTime(string[] memory proposalDescription)
        public
        checkRegistering
    {
        require(
            !votants[msg.sender].isRegistered,
            "Proposition already registreted"
        );
        require(
            (workflowStatus == WorkflowStatus.ProposalsRegistrationStarted &&
                workflowStatus != WorkflowStatus.ProposalsRegistrationEnded),
            "Tu ne peut pas faire de proposition pour l'nstant"
        );

        for (uint256 i = 0; i < proposalDescription.length; i++) {
            proposals.push(
                Proposal({description: proposalDescription[i], voteCount: 0})
            );
        }
        votants[msg.sender].isRegistered = true;
        emit ProposalRegistered(proposalDescription.length);
    }

    function Vote(uint256 _votedProposalId) external checkRegistering {
        require(proposals.length > _votedProposalId);
        proposals[_votedProposalId].voteCount++;
        votants[msg.sender].hasVoted = true;
        votants[msg.sender].votedProposalId = _votedProposalId;
        emit Voted(msg.sender, _votedProposalId);
    }

    function winningProposal() public view returns (uint256 winningProposalId) {
        uint256 winningVoteCount = 0;
        for (uint256 j = 0; j < proposals.length; j++) {
            if (proposals[j].voteCount > winningVoteCount) {
                winningVoteCount = proposals[j].voteCount;
                winningProposalId = j;
            }
        }
    }
}
