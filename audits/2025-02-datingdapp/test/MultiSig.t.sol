// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {Test,console2 } from "forge-std/Test.sol";
import {MultiSigWallet} from "../src/MultiSig.sol";
contract MultiSigTest is Test {
    MultiSigWallet wallet;
    address owner1;
    address owner2;
    address recipient;


    function setUp() public {
        owner1 = makeAddr("owner1");
        owner2 = makeAddr("owner2");
        recipient = makeAddr("recipient");
        wallet = new MultiSigWallet(owner1, owner2);
        vm.deal(address(wallet), 1000);
    }

    function testSubmitTransactionOwner1() public {
        vm.prank(owner1);
        wallet.submitTransaction(recipient, 100);
        assertEq(wallet.getTransactionsLength(), 1);
    }

    function testSubmitTransactionOwner2() public {
        vm.prank(owner2);
        wallet.submitTransaction(recipient, 100);
        assertEq(wallet.getTransactionsLength(), 1);
    }


    function testApprovedTransactionOwner1() public {
        vm.startPrank(owner1);
        wallet.submitTransaction(recipient, 100);
        wallet.approveTransaction(0);
        vm.stopPrank();
        assertEq(wallet.getApprovedByOwner1(0), true);
    }

    function testApprovedTransactionOwner2() public {
        vm.startPrank(owner2);
        wallet.submitTransaction(recipient, 100);
        wallet.approveTransaction(0);
        vm.stopPrank();
        assertEq(wallet.getApprovedByOwner2(0), true);
    }


    function testExecuteTransaction() public {
        uint256 balanceBefore = address(wallet).balance;
        vm.startPrank(owner1);
        wallet.submitTransaction(recipient, 100);
        wallet.approveTransaction(0);
        vm.stopPrank();
        vm.startPrank(owner2);
        wallet.approveTransaction(0);
        wallet.executeTransaction(0);
        vm.stopPrank();
        uint256 balanceAfter = address(wallet).balance;
        assertEq(wallet.getExecuted(0), true);
        assertEq(balanceBefore - balanceAfter, 100);
    }


}