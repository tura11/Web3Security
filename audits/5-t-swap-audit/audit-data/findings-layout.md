### [I-1] No zero check address

**Description:** 
In constructor procotol does not revert on address(0) as param.
**Impact:** 
Informational

**Proof of Concept:**
   constructor(address wethToken) {
        //audit-informational no checks for zero address
        i_wethToken = wethToken;
    }


**Recommended Mitigation:** 
Add if statement to check for address(0);




### [I-2] Wrong ERC20 function usage

**Description:** 
In createPool function we are assining to liquidityTokenSymbol .name() ERC20 fucntion instead of .symbol()
**Impact:** 
Informational
**Proof of Concept:**
     string memory liquidityTokenSymbol = string.concat("ts", IERC20(tokenAddress).name()); //audit-info this should be .symbol()

**Recommended Mitigation:** 
Assing IERC20(tokenAddress).symbol() instead of .name()