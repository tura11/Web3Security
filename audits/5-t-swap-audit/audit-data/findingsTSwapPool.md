### [H-1] Missing Deadline Validation in deposit Allows Execution of Stale Transactions

**Description:** 
The deposit() function accepts a deadline parameter but does not validate it against the current block timestamp. Unlike other time-sensitive functions in the contract (e.g., withdraw, swapExactInput, swapExactOutput), the deposit() function does not use the revertIfDeadlinePassed modifier or any equivalent check.

As a result, a transaction signed by the user with an intended time constraint can still be executed long after the deadline has passed, if it remains pending in the mempool or is deliberately delayed by a block builder, validator, or MEV actor.

This breaks the expected UX and safety guarantees typically associated with deadline parameters in AMM-style protocols (e.g., protection against price movement or execution delay).
**Impact:** 
High,Users may experience unexpected execution at unfavorable pool ratios due to price movement after the intended deadline.

**Proof of Concept:**
User calls deposit() with:

deadline = block.timestamp + 60 (1 minute validity)

Transaction remains pending in the mempool.

After several minutes or hours:

Pool reserves change significantly.

A validator or searcher includes the transaction.

Since no deadline check exists, the deposit executes successfully despite the expired deadline, using the new (possibly worse) pool ratio.

**Recommended Mitigation:** 
Validate deadline in deposit function, use modifier.


### [H-2] Incorrect fee calulcation in `getInputAmountBasedOnOutput` function causes portocol to take too many tokens form users, resulting in lost fees.

**Description:**  the `getInputAmountBasedOnOutput` function is intendted to calculte the amount of tokens a user should deposit given an amount of tokens of outpout tokens. However the fucntion currently mscalculates the resulting amount. WHen calulcating the fee it scales the amount by 10000 instad of 1000.

**Impact:** Protocol takes more fees than expected from users.

**Proof of Concept:**
  function test_InputAmountFeeIsTooHigh() public {
    uint256 inputReserves = 1000 ether;
    uint256 outputReserves = 1000 ether;
    uint256 outputAmount = 100 ether;


    uint256 inputWrong = pool.getInputAmountBasedOnOutput(
        outputAmount,
        inputReserves,
        outputReserves
    );

 
    uint256 numerator = inputReserves * outputAmount * 1000;
    uint256 denominator = (outputReserves - outputAmount) * 997;
    uint256 inputCorrect = numerator / denominator;

    console.log("Wrong input:", inputWrong);
    console.log("Correct input:", inputCorrect);


    assertGt(inputWrong, inputCorrect * 9); 
    }
    [PASS] test_InputAmountFeeIsTooHigh() (gas: 14046)
Logs:
  Wrong input: 1114454474534715256881 10x higher!!
  Correct input: 111445447453471525688 


**Recommended Mitigation:** 

```diff
 function getInputAmountBasedOnOutput(
        uint256 outputAmount,
        uint256 inputReserves,
        uint256 outputReserves
    )
        public
        pure
        revertIfZero(outputAmount)
        revertIfZero(outputReserves)
        returns (uint256 inputAmount)
    {
        return
-            ((inputReserves * outputAmount) * 10000)
+            ((inputReserves * outputAmount) * 1000)
            ((outputReserves - outputAmount) * 997);
    }

```

### [H-3] No slippage protecion in `swapExactOutput` casues users to potentitaly receive way fewer tokens

**Description:** 
he swapExactOutput function does not include any sort of slippage protection. This function is similar to what is done in TSwapPool::swapExactInput, where the function specifies a minOutputAmount, the swapExactOutput function should specify a maxInputAmount.


**Impact:** 
 If market conditions change before the transaciton processes, the user could get a much worse swap.


**Proof of Concept:**

**Recommended Mitigation:** 
We should include a maxInputAmount so the user only has to spend up to a specific amount, and can predict how much they will spend on the protocol.

```diff
 function swapExactOutput(
        IERC20 inputToken, 
+       uint256 maxInputAmount,
.
.
.
        inputAmount = getInputAmountBasedOnOutput(outputAmount, inputReserves, outputReserves);
+       if(inputAmount > maxInputAmount){
+           revert();
+       }        
        _swap(inputToken, inputAmount, outputToken, outputAmount);
```



[H-4] TSwapPool::sellPoolTokens mismatches input and output tokens causing users to receive the incorrect amount of tokens
Description: The sellPoolTokens function is intended to allow users to easily sell pool tokens and receive WETH in exchange. Users indicate how many pool tokens they're willing to sell in the poolTokenAmount parameter. However, the function currently miscalculaes the swapped amount.

This is due to the fact that the swapExactOutput function is called, whereas the swapExactInput function is the one that should be called. Because users specify the exact amount of input tokens, not output.

Impact: Users will swap the wrong amount of tokens, which is a severe disruption of protcol functionality.

Proof of Concept:

Recommended Mitigation:

Consider changing the implementation to use swapExactInput instead of swapExactOutput. Note that this would also require changing the sellPoolTokens function to accept a new parameter (ie minWethToReceive to be passed to swapExactInput)

    function sellPoolTokens(
        uint256 poolTokenAmount,
+       uint256 minWethToReceive,    
        ) external returns (uint256 wethAmount) {
-        return swapExactOutput(i_poolToken, i_wethToken, poolTokenAmount, uint64(block.timestamp));
+        return swapExactInput(i_poolToken, poolTokenAmount, i_wethToken, minWethToReceive, uint64(block.timestamp));
    }



### LOW

### [L-1] `TswapPool::LiquduityAdded` event has parameters out of order

**Description:** When the `LiquiditiyAdded` event is emmited in the `TSwapPool::_addLiquidityMintAndTrasnfer` function logs values in an incorrect order. The `poolTokenToDeposit` shoudl go in the third parameter position, whereas the `wethToDeposit` should go second.

**Impact:**  Event emision is incorrect, leading to off-chain functions potentially malfunctiuoning.

**Proof of Concept:**


**Recommended Mitigation:** 
```diff
- emit LiquidityAdded(msg.sender, poolTokensToDeposit, wethToDeposit);
+ emit LiquidityAdded(msg.sender, wethToDeposit, poolTokensToDeposit);
```



### [L-2] Deafult valuye returned by `swapExactInput` results in incorrect return value given

**Description:** 
The swapExactInput function is expected to return the actual amount of tokens bought by the caller. However, while it declares the named return value ouput it is never assigned a value, nor uses an explict return statement.

**Impact:** 
The return value will always be 0, giving incorrect information to the caller.

**Recommended Mitigation:** 
```diff
   {
        uint256 inputReserves = inputToken.balanceOf(address(this));
        uint256 outputReserves = outputToken.balanceOf(address(this));

-        uint256 outputAmount = getOutputAmountBasedOnInput(inputAmount, inputReserves, outputReserves);
+        output = getOutputAmountBasedOnInput(inputAmount, inputReserves, outputReserves);

-        if (output < minOutputAmount) {
-            revert TSwapPool__OutputTooLow(outputAmount, minOutputAmount);
+        if (output < minOutputAmount) {
+            revert TSwapPool__OutputTooLow(outputAmount, minOutputAmount);
        }

-        _swap(inputToken, inputAmount, outputToken, outputAmount);
+        _swap(inputToken, inputAmount, outputToken, output);
    }
```