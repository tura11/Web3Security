// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Pot} from "./Pot.sol";
import {Ownable} from "lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import {IERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

contract ContestManager is Ownable {
    address[] public contests;
    mapping(address => uint256) public contestToTotalRewards;

    error ContestManager__InsufficientFunds();

    constructor() Ownable(msg.sender) {}

    function createContest(address[] memory players, uint256[] memory rewards, IERC20 token, uint256 totalRewards) //audit-gas should be external
        public
        onlyOwner
        returns (address)
    {
        // Create a new Pot contract
        Pot pot = new Pot(players, rewards, token, totalRewards);
        contests.push(address(pot));
        contestToTotalRewards[address(pot)] = totalRewards;
        return address(pot);
    }

    function fundContest(uint256 index) public onlyOwner { //audit-gas should be external
        Pot pot = Pot(contests[index]);
        IERC20 token = pot.getToken();
        uint256 totalRewards = contestToTotalRewards[address(pot)];

        if (token.balanceOf(msg.sender) < totalRewards) {
            revert ContestManager__InsufficientFunds();
        }

        token.transferFrom(msg.sender, address(pot), totalRewards); //audit- medium we are not checking the transaction return false or true, lead to fake pot contract variables value
    }

    function getContests() public view returns (address[] memory) { //audit-gas should be external

        return contests;
    }

    function getContestTotalRewards(address contest) public view returns (uint256) { //audit-gas should be external
        return contestToTotalRewards[contest];
    }

    function getContestRemainingRewards(address contest) public view returns (uint256) { //audit-gas should be external
        Pot pot = Pot(contest);
        return pot.getRemainingRewards();
    }

    function closeContest(address contest) public onlyOwner { //audit-gas should be external
        _closeContest(contest);
    }

    function _closeContest(address contest) internal {
        Pot pot = Pot(contest);
        pot.closePot();
    }
}
