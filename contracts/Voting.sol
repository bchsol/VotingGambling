// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

contract UupsVoting is Initializable, OwnableUpgradeable, UUPSUpgradeable {

    struct VoteSession {
        string topic;
        bool isVoting;
        uint256 startTime;
        uint256 endTime;
        uint256 totalToken;
        uint256 votingDuration;
        uint256[] optionCounts; // Stores the number of votes for each option
        mapping(uint256=>address[]) voteForOptions; // Stores addresses of voters for each option
        mapping(address => bool) hasVoted;
    }

    uint256 private voteSessionCounter;
    uint256 private bet;

    mapping(uint256=>VoteSession) private voteSessions;
    mapping(uint256=>uint256) private totalOptions;

    event createVote(string topic, uint256 options);
    event endVote(uint256 voteSessionId);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    // Function to create a new voting session with the given number of options
    function createVoteSession(string calldata topic, uint256 options, uint256 duration) external onlyOwner{
        require(options > 1, "Invaild number of options");
        voteSessionCounter++;

        VoteSession storage v = voteSessions[voteSessionCounter];
        v.topic = topic;
        v.isVoting = true;
        v.startTime = block.timestamp;
        v.endTime = block.timestamp + duration;
        v.totalToken = 0;
        v.votingDuration = duration;
        v.optionCounts = new uint256[](options);
        totalOptions[voteSessionCounter] = options;

        emit createVote(topic, options);
    }

    // Function to vote for a specific option in a voting session
    function vote(uint256 voteSessionId, uint256 option) external payable{
        require(!voteSessions[voteSessionId].hasVoted[_msgSender()], "You have already voted");
        require(voteSessions[voteSessionId].isVoting, "Voting has ended");
        require(voteSessions[voteSessionId].endTime >= block.timestamp, "Voting has ended");
        require(msg.value == bet, "Insufficient tokens to vote");
        require(option < totalOptions[voteSessionId],"Invaild voting option");

        voteSessions[voteSessionId].hasVoted[_msgSender()] = true;

        voteSessions[voteSessionId].optionCounts[option] += 1;
        voteSessions[voteSessionId].voteForOptions[option].push(_msgSender());

        voteSessions[voteSessionId].totalToken += bet;
    }

    // Function to end a voting session and distribute rewards
    function endVoteSession(uint256 voteSessionId) external onlyOwner{
        require(voteSessions[voteSessionId].endTime < block.timestamp, "Voting not ended");

        voteSessions[voteSessionId].isVoting = false;
        distributeReward(voteSessionId);

        emit endVote(voteSessionId);
    }

    // Function to distribute rewards to the winning option voters
    function distributeReward(uint256 voteSessionId) internal{
        uint256 totalToken = voteSessions[voteSessionId].totalToken;
        uint256[] memory optionCounts = voteSessions[voteSessionId].optionCounts;

        // Find the option with the minimum votes
        uint256 minVoteCount = optionCounts[0];
        uint256 winningOption = 0;
        for(uint256 i = 1; i < optionCounts.length; i++) {
            if(optionCounts[i] < minVoteCount) {
                minVoteCount = optionCounts[i];
                winningOption = i;
            }
        }

        // In case of a tie, keep the funds in the contract or perform other actions
        if(minVoteCount == 0) {
            return;
        }

        // Distribute the reward to the winning option voters
        address[] memory winners = voteSessions[voteSessionId].voteForOptions[winningOption];
        uint256 tokensPerWinner = totalToken / winners.length;

        for(uint256 i = 0; i < winners.length; i++) {
            payable(winners[i]).transfer(tokensPerWinner);
        }

    }

    // Function to set the betting amount
    function setBetPrice(uint256 newBet) external onlyOwner {
        bet = newBet;
    }

    function forceVotingEnd(uint256 voteSessionId) external onlyOwner {
        voteSessions[voteSessionId].isVoting = false;
        distributeReward(voteSessionId);

        emit endVote(voteSessionId);
    }

    // Function to get voting session information
    function getVoteSession(uint256 voteSessionId) public view returns(string memory topic, uint256 startTime, uint256 endTime, uint256 totalToken){
        VoteSession storage session = voteSessions[voteSessionId];
        return(
            session.topic,
            session.startTime,
            session.endTime,
            session.totalToken
        );
    }

    function initialize() initializer public {
        __Ownable_init();
        __UUPSUpgradeable_init();
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        onlyOwner
        override
    {}
}
