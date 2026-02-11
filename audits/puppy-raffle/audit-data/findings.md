### [L-1] Old version of solidity

**Description:**  contract ./src/PuppyRaffle.sol use 0.7.4 version of solidity, 0.8.0 above are more safier to use.

**Impact:**  Possibilty of over/underflow, in verions below 0.8.0 over/underflow arent automaticly checked by solidity.

**Proof of Concept:**
totalFees = totalFees + uint64(fee); //q what if fee would be over 2^63??

**Recommended Mitigation:** Using newer version of solidity



### [H-1] Denial of Service

**Description:** Enter raffle function uses for loop to iterate through players and push them into players array, but each subsequent itearition will cost more and more gas so the later u will be the more gas this enter would cost you.

**Impact:**  Denial of entering raffle with huge amount of players.

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