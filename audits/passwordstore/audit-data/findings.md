### [S-#] Storing the password on-chain make it visable to anyone and no loner private.

**Description:**  All data stored on chain is visable to anyone.
PasswordStore::s_password variable is intended to be private and only accesed through the PasswordStore::GetPassword  function which is inteded to be only called by owner

**Impact:** Anyone can see your password its not private as solidity status said.

**Proof of Concept:**
make anvil


make deploy to deploy your contract

forge cast 'your contaract address' 1 -rpc--url:127.0.0.1"8545

you will get output with bytes32 and u can decode it like that


cast pasre-bytes32-string "your output"
and the output of this command is myPassword


**Recommended Mitigation:** 
Due to this, You should encrypt the password off-chain  then store the encrypted password on-chain.