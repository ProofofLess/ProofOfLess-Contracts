#  [WIP] Twitter Quest Contract

# 🪜 Installation
To use this app locally, you'll need to do the following:

# CMD (Run Local Polygon Fork Testing)
run thes command into the project file directory
- `cp .env.example .env`
- `npm install`
- `npx hardhat clean`
- `npx hardhat compile`
- `npx hardhat test`
```

# Deployed Address [Polygon]
-
-
-

# Deployed Address [Mumbai]
- TwitterQuest Contract : 0x53cCBEBB8bbdD0a5Db0874CDFb7769d92F3e5Fe5
- MemberShip Contract : 0x31cfE9035FE761DA7b1Cbcb7Ab53C6bE5992585B
- Less Token Contract : 0x8B47908Ef7bcc622e06c107827Fc346f12526eFD

# ✨ TODO ✨: 
- [~] Check Waiting List (waiting list index multiple increments ?) / Balances After each steps
- [~] Check User Owner Of for Quest Registering
- [~] Check every Required & Roles/ make false tesing (every case must be covered)
- [~] Add Events
- [~] Add Nft Increments
- [~] Add $Less Rewards (Twitter Quest Special Minter ? Special Distributeur ?)
- [] Add Destinataire / Sending for/To Fees extracted 
- [] Add Auto Select Fees for selected Contest Coin (decimals)
- [] Add One Week Window Entry (is necessary w oracle restriction ?)

- [] Check All Membership / Token / Quest Functions Restrictions

# USER FLOW : 
1 / user supply funds to pool for multiple entries if desired  
2 / users subscribe to waiting list (join next quest auto)
3.1 / end of previous quest period
3 / oracle subscribe waiting list to next quest
4 / oracle update winners from computed API data 
5 / oracle initialize new cycle + distribute reward to winners 
6 / oracle subscribe waiting list and clean users without required funds 