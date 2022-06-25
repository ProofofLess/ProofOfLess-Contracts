// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `npx hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
// import { ethers } from "hardhat";
const hre = require("hardhat");

async function main() {
  // Hardhat always runs the compile task when running scripts with its command
  // line interface.
  //
  // If this script is run directly using `node` you may want to call compile
  // manually to make sure everything is compiled
  // await hre.run('compile');

  // We get the contract to deploy
  const TwitterQuest = await hre.ethers.getContractFactory("TwitterQuest");
  const twitterQuest = await TwitterQuest.deploy(process.env.GNOSIS_ADDRESS, process.env.ORACLE_ADDRESS);
  await twitterQuest.deployed();

  const MemberShip = await hre.ethers.getContractFactory("MemberShip");
  const memberShip = await MemberShip.deploy(process.env.GNOSIS_ADDRESS, process.env.ORACLE_ADDRESS);
  await memberShip.deployed();

  const LessToken = await hre.ethers.getContractFactory("LessToken");
  const lessToken = await LessToken.deploy(process.env.GNOSIS_ADDRESS, process.env.ORACLE_ADDRESS);
  await lessToken.deployed();

  console.log(`    🟡 Contracts Deployed ✅ Awaiting Initialization ⏱`
);

  let USDCAddress = "0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174";

  await twitterQuest.initialize(
    hre.ethers.utils.parseUnits('10', 6), // entryCost
    hre.ethers.utils.parseUnits('10', 6), // fees
    1, // delayPeriod
    USDCAddress, // listedToken / contestEntryToken
    memberShip.address, // NFT Contract Address
    lessToken.address // Reward Token Contract Address

  )

  let txEntryCost = await twitterQuest.entryCost();
  let txFees = await twitterQuest.fees();
  let txDelay = await twitterQuest.delayPeriod();
  let txEntryToken = await twitterQuest.contestEntryToken();



  console.log(`    🟢 Deployment Results :
  Twitter Quest Deployed to : ${twitterQuest.address}
  MemberShip Deployed to : ${memberShip.address}
  Less Token Deployed to : ${lessToken.address}
  -- Twitter Quest Initializied -- 
  Entry Cost : ${hre.ethers.utils.formatUnits(txEntryCost.toString(), 6)}
  Fees Deducted : ${hre.ethers.utils.formatUnits(txFees.toString(), 6)}
  Period Duration of One Quest : ${txDelay}
  Token Selected for Next Quest : ${txEntryToken}



  `
);

}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
