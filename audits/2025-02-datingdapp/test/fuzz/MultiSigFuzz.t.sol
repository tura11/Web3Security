// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {Test} from "forge-std/Test.sol";
import {MultiSigWallet} from "../../src/MultiSig.sol";
contract MultiSigFuzz is Test{

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


    function test_FuzzSubmitTransactionOwner1(address to, uint256 value) public {
        vm.assume(to != address(0));
        vm.assume(value > 0);
        vm.prank(owner1);
        wallet.submitTransaction(to, value);
        assertEq(wallet.getTransactionsLength(), 1);
    }
}


// INVARIANT 1: Only executed transactions can have both approvals
// INVARIANT 2: Transaction count never decreases
// INVARIANT 3: Wallet balance never goes negative
// INVARIANT 4: Only owners can approve transactions
// INVARIANT 5: Can't approve same transaction twice