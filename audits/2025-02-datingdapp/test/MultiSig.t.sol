// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {Test } from "forge-std/Test.sol";
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
}