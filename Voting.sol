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
        require(whitelist[msg.sender] == true, "you are not authorized to participate");
        _;
    }

    modifier checkVote() {
        require(
            votants[msg.sender].isRegistered =
                true &&
                !votants[msg.sender].hasVoted &&
                workflowStatus == WorkflowStatus.VotingSessionStarted &&
                workflowStatus != WorkflowStatus.VotingSessionEnded,
            "Your can't vote"
        );
        _;
    }

    constructor() onlyOwner {
       
        changeStatus();
    }

    function changeStatus() public onlyOwner {
        adminWhitelist(0x78731D3Ca6b7E34aC0F824c42a7cC18A495cabaB);
        require (block.timestamp >= 2 minutes);
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
        require(workflowStatus == WorkflowStatus.RegisteringVoters || workflowStatus == WorkflowStatus.ProposalsRegistrationStarted);
        require(
            !whitelist[_voterAddress],
            "This address is already whitelisted !"
        );
        whitelist[_voterAddress] = true;
    }

    function proposalTime(string[] memory proposalDescription)
       external
        checkRegistering
    {
        require(
            !votants[msg.sender].isRegistered,
            "Your proposition si already registreted"
        );
        require(
            (workflowStatus == WorkflowStatus.ProposalsRegistrationStarted &&
                workflowStatus != WorkflowStatus.ProposalsRegistrationEnded),
            "You can't do propositions a this time "
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
        require(proposals.length > _votedProposalId, "Please chose existing proposition  ");
        proposals[_votedProposalId].voteCount++;
        votants[msg.sender].hasVoted = true;
        votants[msg.sender].votedProposalId = _votedProposalId;
        emit Voted(msg.sender, _votedProposalId);
    }

    function winningProposal() external view returns (uint256 winningProposalId) {
        uint256 winningVoteCount = 0;
        for (uint256 j = 0; j < proposals.length; j++) {
            if (proposals[j].voteCount > winningVoteCount) {
                winningVoteCount = proposals[j].voteCount;
                winningProposalId = j;
            }
        }
    }
}