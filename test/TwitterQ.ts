import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { BigNumberish } from "ethers";
import { formatEther, formatUnits, parseEther, parseUnits } from "ethers/lib/utils";
import { ethers, network } from "hardhat";
import { TwitterQuest, LessToken, MemberShip, IERC20Metadata } from "../typechain";
import { resetFork } from "../utils/resetFork"
import { checkEnv } from "../utils/checkEnv"
import 'dayjs' 


describe("Test Full Users Flow", async () => {
    let ADMINADDRESS = "0x8af97264482b59c7aa11010907710dee6d8d8c6c"; // Dev Account
    let FIRSTUSERADDRESS = "0x075e72a5eDf65F0A5f44699c7654C1a76941Ddc8";
    let SECONDUSERADDRESS = "0xab9952041329fda60288d17116b8cb959c920713";
    let THIRDUSERADDRESS = "0xa4496f752979881a170d7a33c5ac3204388ebead"
    let DBADMINADDRESS = "0x8af97264482b59c7aa11010907710dee6d8d8c6c"; // GK1

    let admin: SignerWithAddress,
        firstUser: SignerWithAddress,
        secondUser: SignerWithAddress,
        thirdUser: SignerWithAddress,
        dbAdmin: SignerWithAddress;
    
    let twitterQuest: TwitterQuest, lessToken: LessToken, membership: MemberShip;

    let dai: IERC20Metadata, secondToken: IERC20Metadata;
    let less: IERC20Metadata;

    let amountToSupply: any = ethers.utils.parseUnits('15', 6),
        amountToLock: any = ethers.utils.parseUnits('15', 6),
        amountToApprove: any = ethers.utils.parseUnits('500', 6);
 
    let daiAddress: string = "0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174"; // USDC polygon
       let secondTokenAddress: string = "0x8f3Cf7ad23Cd3CaDbD9735AFf958023239c6A063"; // dai polygon 

    async function getImpersonatedSigner(address: string): Promise<SignerWithAddress> {
        await ethers.provider.send(
            'hardhat_impersonateAccount',
            [address]
        );

        return await ethers.getSigner(address);
    }
    const wait = (seconds : number) => {
        const milliseconds = seconds * 1000
        return new Promise(resolve => setTimeout(resolve, milliseconds))
    }

    before(async () => {
        resetFork(28729129);SECONDUSERADDRESS

        admin = await getImpersonatedSigner(ADMINADDRESS);        
        await ethers.provider.send(
            'hardhat_impersonateAccount',
            [admin.address]
        );
        firstUser = await getImpersonatedSigner(FIRSTUSERADDRESS); 
        secondUser = await getImpersonatedSigner(SECONDUSERADDRESS); 
        thirdUser = await getImpersonatedSigner(THIRDUSERADDRESS); 
        dbAdmin = await getImpersonatedSigner(DBADMINADDRESS); 

        dai = await ethers.getContractAt("IERC20Metadata", daiAddress);
        secondToken = await ethers.getContractAt("IERC20Metadata", secondTokenAddress);
          
        const TwitterQuest = await ethers.getContractFactory("TwitterQuest");
        twitterQuest = await TwitterQuest.deploy(admin.address, dbAdmin.address);
        await twitterQuest.deployed();
        // console.log("twitterQuest deployed at : ", twitterQuest.address);

        const MemberShip = await ethers.getContractFactory("MemberShip");
        membership = await MemberShip.deploy(admin.address, dbAdmin.address);
        await membership.deployed();
        // console.log("twitterQuest deployed at : ", twitterQuest.address);

        const LessToken = await ethers.getContractFactory("LessToken");
        lessToken = await LessToken.deploy(admin.address, dbAdmin.address);
        await lessToken.deployed();
        // console.log("twitterQuest deployed at : ", twitterQuest.address);


        // await dai.connect(admin).approve(twitterQuest.address, amountToDeposit);
        // await twitterQuest.connect(admin).deposit(dai.address, amountToDeposit);
        // initialBalance = await twitterQuest.balance(dai.address)

        console.log(`    📜 Protocol Created.`);

    });

    it("Should Pass Normal Users Flow", async () => {

        console.log(`\n1️⃣  Step 1 : Users[3] -> Mint MemberShip
                                    Admin -> Grant Minter Role & List/Set Actual Token & Set MemberShip Address
                    `);
        let MINTERROLE = await membership.connect(admin).MINTER_ROLE();
        let ADMINROLE = await membership.connect(admin).DEFAULT_ADMIN_ROLE();

        await membership.connect(admin).grantRole(ADMINROLE, twitterQuest.address);

        await membership.connect(admin).grantRole(MINTERROLE, firstUser.address);
        await membership.connect(admin).grantRole(MINTERROLE, secondUser.address);
        await membership.connect(admin).grantRole(MINTERROLE, thirdUser.address);

        await membership.connect(firstUser).safeMint(firstUser.address, "uriTest1");
        await membership.connect(secondUser).safeMint(secondUser.address, "uriTest2");
        await membership.connect(thirdUser).safeMint(thirdUser.address, "uriTest3");

        await twitterQuest.connect(admin)
            .initialize(
                ethers.utils.parseUnits('10', 6), // entryCost
                ethers.utils.parseUnits('10', 6), // fees
                1, // delayPeriod
                dai.address, // listedToken / contestEntryToken
                membership.address, // NFT Contract Address
                lessToken.address // Reward Token Contract Address
            );

        let txHasRole1 = await membership.connect(firstUser).balanceOf(firstUser.address);
        let txHasRole2 = await membership.connect(secondUser).balanceOf(secondUser.address);
        let txHasRole3 = await membership.connect(thirdUser).balanceOf(thirdUser.address);
    
        let txActualQuestToken = await twitterQuest.connect(firstUser).contestEntryToken();

        console.log(`    🟢 Step 1 Results : 
                        Token Listed For Quest : ${txActualQuestToken}    
                        User1 MemberShip Balance : ${txHasRole1}
                        User2 MemberShip Balance : ${txHasRole2}
                        User3 MemberShip Balance : ${txHasRole3}

                    `);

        
        console.log(`\n2️⃣  Step 2 : Users[3] -> Supply To Pool && Subscribe To Waiting List`);
     
        await dai.connect(firstUser).approve(twitterQuest.address, amountToApprove);
        await dai.connect(secondUser).approve(twitterQuest.address, amountToApprove);
        await dai.connect(thirdUser).approve(twitterQuest.address, amountToApprove);
        await twitterQuest.connect(firstUser).supplyToPool(daiAddress, amountToSupply);
        await twitterQuest.connect(secondUser).supplyToPool(daiAddress, amountToSupply);
        await twitterQuest.connect(thirdUser).supplyToPool(daiAddress, amountToSupply);
        await twitterQuest.connect(firstUser).registerToWaitingList();
        await twitterQuest.connect(secondUser).registerToWaitingList();
        await twitterQuest.connect(thirdUser).registerToWaitingList();

        let txUserShares1 = await twitterQuest.connect(firstUser).userPoolShares(firstUser.address, dai.address);
        let txUserShares2 = await twitterQuest.connect(secondUser).userPoolShares(secondUser.address, dai.address);
        let txUserShares3 = await twitterQuest.connect(thirdUser).userPoolShares(thirdUser.address, dai.address);
        let txFirstWaitingList = await twitterQuest.connect(firstUser).getAllSubscribed();

        console.log(`    🟢 Step 2 Results : 
                    User1 Funds Supplied : ${ethers.utils.formatUnits(txUserShares1.toString(), 6)}
                    User2 Funds Supplied : ${ethers.utils.formatUnits(txUserShares2.toString(), 6)}
                    User3 Funds Supplied : ${ethers.utils.formatUnits(txUserShares3.toString(), 6)}
                    Registered to Waiting List : ${txFirstWaitingList}
                    `
        );


        console.log(`\n3️⃣  Step 3 : Oracle -> Register Waiting List to Participants (Lock Funds & Set Weekly Goal)`);
        await twitterQuest.connect(dbAdmin).lockEntryFunds(
            [FIRSTUSERADDRESS, SECONDUSERADDRESS, THIRDUSERADDRESS],
            [0, 1, 2],
            [0, 1, 2],
            [amountToLock, amountToLock, amountToLock],
            [9, 9, 9],
            [dai.address, dai.address, dai.address]
        )
        let txDBSubscription = await twitterQuest.connect(firstUser).getAllParticipants();
        let txQuestReward = await twitterQuest.connect(firstUser).questBalance(dai.address);
        let txEntryCost = await twitterQuest.connect(firstUser).entryCost();
        let txFees = await twitterQuest.connect(firstUser).fees();

        console.log(`    🟢 Step 3 Results : 
                    Total Participants Number: ${txDBSubscription}
                    Entry Cost : ${ethers.utils.formatUnits(txEntryCost.toString(), 6)}
                    Total Actual Quest Reward: ${ethers.utils.formatUnits(txQuestReward.toString(), 6)}
                    Fees Deducted : ${ethers.utils.formatUnits(txFees.toString(), 6)}
                    `
        );


        console.log(`\n4️⃣  Step 4 : Update 1 Winner`);
        await twitterQuest.connect(dbAdmin).updateUserTwitterData(firstUser.address, true);
        let txisWinner = await twitterQuest.connect(firstUser).userTwitterData(firstUser.address);

        console.log(`    🟢 Step 4 Results : 
                    user1 winner : datas : ${txisWinner}
                    `
        );

        
        console.log(`\n5️⃣  Step 5 : End Cycle + ReEnter If Enought Funds Availaible in Waiting List`);
        await twitterQuest.connect(dbAdmin).newCycle(dai.address);
        let txMBalU1 = await twitterQuest.connect(firstUser).userPoolShares(FIRSTUSERADDRESS, daiAddress);

        // let txWinnerIs = await twitterQuest.participants();
        console.log(`    🟡 Cycle Ended : 
                    Bal Winner : ${ethers.utils.formatUnits(txMBalU1.toString(), 6)}
                    Starting Next Quest ⏱

                    `
        );

        await twitterQuest.connect(dbAdmin).lockEntryFunds(
            [FIRSTUSERADDRESS, SECONDUSERADDRESS, THIRDUSERADDRESS],
            [0, 1, 2],
            [0, 1, 2],
            [amountToLock, amountToLock, amountToLock],
            [9, 9, 9],
            [dai.address, dai.address, dai.address]
        )
        let txSecondCycle = await twitterQuest.connect(secondUser).getAllParticipants();
        let txWaitingListUpdated = await twitterQuest.connect(secondUser).getAllSubscribed();
       
        let txFBalU1 = await twitterQuest.connect(firstUser).userPoolShares(FIRSTUSERADDRESS, daiAddress);
        let txFBalU2 = await twitterQuest.connect(secondUser).userPoolShares(SECONDUSERADDRESS, daiAddress);
        let txFBalU3 = await twitterQuest.connect(thirdUser).userPoolShares(THIRDUSERADDRESS, daiAddress);

        let txFNftStats = await membership.connect(firstUser).userProfil(0, firstUser.address);


        console.log(`    🟢 Step 5 Results : 
                    🌟Total Final Participants for new Quest : ${txSecondCycle}
                    🌟Total Final WaitingList Still Subscribed : ${txWaitingListUpdated}
                    🌟Total Final Bal User 1 : ${ethers.utils.formatUnits(txFBalU1.toString(), 6)} 
                    🌟Total Final Bal User 2 : ${ethers.utils.formatUnits(txFBalU2.toString(), 6)}
                    🌟Total Final Bal User 3 : ${ethers.utils.formatUnits(txFBalU3.toString(), 6)}
                    🌟Winner NFT Profil : ${txFNftStats}


                    `
        );



    });
}) 

