// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "lib/openzeppelin-contracts/contracts/access/Ownable.sol";

contract Pot is Ownable(msg.sender) {
    error Pot__RewardNotFound();
    error Pot__InsufficientFunds(); //audit-gas unused error
    error Pot__StillOpenForClaim();

    address[] private i_players;
    uint256[] private i_rewards;
    address[] private claimants;
    uint256 private immutable i_totalRewards;
    uint256 private immutable i_deployedAt;
    IERC20 private immutable i_token;
    mapping(address => uint256) private playersToRewards;
    uint256 private remainingRewards;
    uint256 private constant managerCutPercent = 10;

    constructor(address[] memory players, uint256[] memory rewards, IERC20 token, uint256 totalRewards) {
        i_players = players;
        i_rewards = rewards;
        i_token = token;
        i_totalRewards = totalRewards;
        remainingRewards = totalRewards;
        i_deployedAt = block.timestamp;

        // i_token.transfer(address(this), i_totalRewards);

        for (uint256 i = 0; i < i_players.length; i++) {
            playersToRewards[i_players[i]] = i_rewards[i]; // audit-high we dont check the lenght of rewards array what if we got 3  players and 2 rewards
        }
    }

    function claimCut() public { //audit-gas should be external
        address player = msg.sender;
        uint256 reward = playersToRewards[player];
        if (reward <= 0) {
            revert Pot__RewardNotFound();
        }
        playersToRewards[player] = 0;
        remainingRewards -= reward;
        claimants.push(player);
        _transferReward(player, reward); 
    }

    function closePot() external onlyOwner {
        if (block.timestamp - i_deployedAt < 90 days) {
            revert Pot__StillOpenForClaim();
        }
        if (remainingRewards > 0) {
            uint256 managerCut = remainingRewards / managerCutPercent;
            i_token.transfer(msg.sender, managerCut); //audit-low we are not checking the transaction return false or true

            uint256 claimantCut = (remainingRewards - managerCut) / i_players.length; // audit-high logic issue with division lead to stuck funds in contract forever
            for (uint256 i = 0; i < claimants.length; i++) { //audit-gas better store calimants length in a variable and loop through it
                _transferReward(claimants[i], claimantCut);
            }
        }
    }

    function _transferReward(address player, uint256 reward) internal {
        i_token.transfer(player, reward); // audit-medium we are not checking the transaction return false or true
    }

    function getToken() public view returns (IERC20) { //audit-gas should be external
        return i_token;
    }
 
    function checkCut(address player) public view returns (uint256) { //audit-gas should be external
        return playersToRewards[player];
    }

    function getRemainingRewards() public view returns (uint256) { //audit-gas should be external
        return remainingRewards;
    }
}
