// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";
import {LikeRegistry} from "../../src/LikeRegistry.sol";
import {SoulboundProfileNFT} from "../../src/SoulboundProfileNFT.sol";

contract LikeRegistryTest is Test {
    LikeRegistry like;
    SoulboundProfileNFT profileNft;

    address user1;
    address user2;

    function setUp() public {
        user1 = makeAddr("user1");
        user2 = makeAddr("user2");
        profileNft = new SoulboundProfileNFT();
        like = new LikeRegistry(address(profileNft));
        vm.deal(user1, 100 ether);
        vm.deal(user2, 100 ether);
    }


    function testLikeUser() public {
        vm.prank(user1);
        
        profileNft.mintProfile("User1", 20, "ipfs://profile1");

        vm.prank(user2);

        profileNft.mintProfile("User2", 20, "ipfs://profile2");

        vm.startPrank(user1);
        like.likeUser{value: 1 ether}(user2);
        assertEq(like.getLiked(user2), true);
        vm.stopPrank();
    }

    function testMatches() public {
        vm.prank(user1);
        profileNft.mintProfile("User1", 20, "ipfs://profile1");
        vm.prank(user2);
        profileNft.mintProfile("User2", 20, "ipfs://profile2");
        vm.startPrank(user1);
        like.likeUser{value: 1 ether}(user2);
        vm.stopPrank();
        
        vm.startPrank(user2);
        like.likeUser{value: 1 ether}(user1);
        vm.stopPrank();
        vm.prank(user1);
        address[] memory matchesUser1 = like.getMatches();
        assertEq(matchesUser1.length, 1);
        assertEq(matchesUser1[0], user2);

        vm.prank(user2);
        address[] memory matchesUser2 = like.getMatches();
        assertEq(matchesUser2.length, 1);
        assertEq(matchesUser2[0], user1);
    }
}