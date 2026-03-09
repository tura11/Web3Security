HIGH-01 — Reentrancy in mintProfile allows minting multiple profiles
Description
mintProfile should allow only one profile per address. However, _safeMint makes an external call to onERC721Received on the recipient before the state variables profileToToken and _profiles are updated, violating the Checks-Effects-Interactions pattern and enabling reentrancy.

// Root cause in the codebase with @> marks to highlight the relevant section
Risk
Likelihood:

A malicious user deploys a contract implementing onERC721Received that re-enters mintProfile. Since profileToToken[msg.sender] is still 0 during the external call, the check passes on every reentrant call.Impact:

A single address can mint unlimited profile NFTs, completely breaking the one-profile-per-address invariant and potentially spamming the protocol.

Proof of Concept
contract Attacker {
    SoulboundProfileNFT nft;
    uint256 count;
​
    constructor(address _nft) { nft = SoulboundProfileNFT(_nft); }
​
    function attack() external {
        nft.mintProfile("hacker", 25, "ipfs://x");
    }
​
    function onERC721Received(address, address, uint256, bytes memory)
        public returns (bytes4)
    {
        if (count < 3) {
            count++;
            nft.mintProfile("hacker", 25, "ipfs://x"); // reentrant!
        }
        return this.onERC721Received.selector;
    }
}
Recommended Mitigation
function mintProfile(...) external {
    require(profileToToken[msg.sender] == 0, "Profile already exists");
​
    uint256 tokenId = ++_nextTokenId;
+   _profiles[tokenId] = Profile(name, age, profileImage);
+   profileToToken[msg.sender] = tokenId;
    _safeMint(msg.sender, tokenId);
-   _profiles[tokenId] = Profile(name, age, profileImage);
-   profileToToken[msg.sender] = tokenId;
​
    emit ProfileMinted(msg.sender, tokenId, name, age, profileImage);
}


HIGH-02 — userBalances never updated, ETH permanently locked
Description
likeUser accepts ETH (msg.value >= 1 ether) but never assigns it to userBalances. When a match occurs, matchRewards reads both users' balances which are always 0, meaning the MultiSig receives 0 ETH while all ETH sent by users is permanently locked in LikeRegistry.

function likeUser(address liked) external payable {
    require(msg.value >= 1 ether, "Must send at least 1 ETH");
    // @> msg.value never assigned to userBalances!
    likes[msg.sender][liked] = true;
}
​
function matchRewards(address from, address to) internal {
    uint256 matchUserOne = userBalances[from]; // @> always 0
    uint256 matchUserTwo = userBalances[to];   // @> always 0
Risk
Likelihood:

Occurs on every single match — 100% of cases.

Impact:

All ETH sent by users is stuck in the contract forever. Match rewards are always zero. Users lose funds with no way to recover them.

Proof of Concept
// Alice calls likeUser{value: 1 ether}(Bob)
// Bob calls likeUser{value: 1 ether}(Alice) → match triggered
// matchRewards reads userBalances[Alice] = 0, userBalances[Bob] = 0
// MultiSig receives 0 ETH
// 2 ETH stuck in LikeRegistry forever
Recommended Mitigation
function likeUser(address liked) external payable {
    require(msg.value >= 1 ether, "Must send at least 1 ETH");
+   uint256 fee = (msg.value * FIXEDFEE) / 100;
+   userBalances[msg.sender] += msg.value - fee;
+   totalFees += fee;
​
    require(!likes[msg.sender][liked], "Already liked");
    // ...
}




MEDIUM-03 — burnProfile does not follow CEI pattern
DescriptionburnProfile calls _burn(tokenId) before clearing profileToToken and _profiles. While _burn on a soulbound token has limited external call surface, it still emits events and calls internal hooks before state is cleaned up, which is inconsistent with safe coding practices.
function burnProfile() external {
    uint256 tokenId = profileToToken[msg.sender];
    _burn(tokenId);                        // @> external effects before state cleanup
    delete profileToToken[msg.sender];     // should come first
    delete _profiles[tokenId];
}
Risk
Likelihood:

every time when user call burnProfile function

Impact:

Emit the events and calls internal hooks before state is cleanedup which is incosisnent

lProof of Concept

​
Recommended Mitigation
function burnProfile() external {
    uint256 tokenId = profileToToken[msg.sender];
    require(tokenId != 0, "No profile found");
    require(ownerOf(tokenId) == msg.sender, "Not profile owner");
​
+   delete profileToToken[msg.sender];
+   delete _profiles[tokenId];
    _burn(tokenId);
-   delete profileToToken[msg.sender];
-   delete _profiles[tokenId];
​
    emit ProfileBurned(msg.sender, tokenId);
}



MEDIUM-03 — burnProfile does not follow CEI pattern
DescriptionburnProfile calls _burn(tokenId) before clearing profileToToken and _profiles. While _burn on a soulbound token has limited external call surface, it still emits events and calls internal hooks before state is cleaned up, which is inconsistent with safe coding practices.
function burnProfile() external {
    uint256 tokenId = profileToToken[msg.sender];
    _burn(tokenId);                        // @> external effects before state cleanup
    delete profileToToken[msg.sender];     // should come first
    delete _profiles[tokenId];
}
Risk
Likelihood:

every time when user call burnProfile function

Impact:

Emit the events and calls internal hooks before state is cleanedup which is incosisnent

lProof of Concept

​
Recommended Mitigation
function burnProfile() external {
    uint256 tokenId = profileToToken[msg.sender];
    require(tokenId != 0, "No profile found");
    require(ownerOf(tokenId) == msg.sender, "Not profile owner");
​
+   delete profileToToken[msg.sender];
+   delete _profiles[tokenId];
    _burn(tokenId);
-   delete profileToToken[msg.sender];Description
App owner can block users at will, causing users to have their funds locked.

Vulnerability Details
SoulboundProfileNFT::blockProfile can block any app's user at will.

/// @notice App owner can block users
function blockProfile(address blockAddress) external onlyOwner {
    uint256 tokenId = profileToToken[blockAddress];
    require(tokenId != 0, "No profile found");
​
    _burn(tokenId);
    delete profileToToken[blockAddress];
    delete _profiles[tokenId];
​
    emit ProfileBurned(blockAddress, tokenId);
}
Proof of Concept
The following code demonstrates the scenario where the app owner blocks bob and he is no longer able to call LikeRegistry::likeUser. Since the contract gives no posibility of fund withdrawal, bob's funds are now locked.

Place test_blockProfileAbuseCanCauseFundLoss in testSoulboundProfileNFT.t.sol:

function test_blockProfileAbuseCanCauseFundLoss() public {
    vm.deal(bob, 10 ether);
    vm.deal(alice, 10 ether);
​
    // mint a profile NFT for bob
    vm.prank(bob);
    soulboundNFT.mintProfile("Bob", 25, "ipfs://profileImage");
​
    // mint a profile NFT for Alice
    vm.prank(alice);
    soulboundNFT.mintProfile("Alice", 25, "ipfs://profileImage");
​
    // alice <3 bob
    vm.prank(alice);
    likeRegistry.likeUser{value: 1 ether}(bob);
​
    vm.startPrank(owner);
    soulboundNFT.blockProfile(bob);
    assertEq(soulboundNFT.profileToToken(msg.sender), 0);
​
    vm.startPrank(bob);
    vm.expectRevert("Must have a profile NFT");
    // bob is no longer able to like a user, as his profile NFT is deleted
    // his funds are effectively locked
    likeRegistry.likeUser{value: 1 ether}(alice);
}
And run the test:

$ forge test --mt test_blockProfileAbuseCanCauseFundLoss
Ran 1 test for test/testSoulboundProfileNFT.t.sol:SoulboundProfileNFTTest
[PASS] test_blockProfileAbuseCanCauseFundLoss() (gas: 326392)
Suite result: ok. 1 passed; 0 failed; 0 skipped; finished in 1.42ms (219.63µs CPU time)
​
Ran 1 test suite in 140.90ms (1.42ms CPU time): 1 tests passed, 0 failed, 0 skipped (1 total tests)
Impact
App users can have their funds locked, as well as miss out on potential dates.

Recommendations
Add a voting mechanism to prevent abuse and/or centralization of the feature.
-   delete _profiles[tokenId];
​
    emit ProfileBurned(msg.sender, tokenId);
}
