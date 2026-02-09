### [S-#] Old version of solidity

**Description:**  contract ./src/PuppyRaffle.sol use 0.7.4 version of solidity, 0.8.0 above are more safier to use.

**Impact:**  Possibilty of over/underflow, in verions below 0.8.0 over/underflow arent automaticly checked by solidity.

**Proof of Concept:**
totalFees = totalFees + uint64(fee); //q what if fee would be over 2^63??

**Recommended Mitigation:** Using newer version of solidity