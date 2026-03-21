# [H-1] closePot divides by i_players.length instead of claimants.length, permanently underpaying remaining claimants
# Description:
When closePot is called, it calculates each claimant's share by dividing by i_players.length — the total number of registered players. However, players who already called claimCut() are not in claimants so the divisor is artificially inflated and each remaining claimant receives far less than their fair share. The difference is never recovered.
# Impact:

Remaining claimants are systematically underpaid relative to their entitled rewards

The shortfall is permanently locked in the contract with no recovery mechanism

# Proof of Concept:
// 3 players: A, B, C — each owed 300 tokens
// A and B call claimCut() before closePot
// remainingRewards = 300, claimants = [C], i_players.length = 3
​
uint256 claimantCut = 300 / 3; // = 100 — wrong, C is owed 300
// C receives 100, 200 tokens locked forever 
# Recommended Mitigation:

- remove this code
-uint256 claimantCut = (remainingRewards - managerCut) / i_players.length;
+uint256 claimantCut = (remainingRewards - managerCut) / claimants.length;
+ add this code