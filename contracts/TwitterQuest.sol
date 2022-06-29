// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

// For Testing / May Be Deleted
import "hardhat/console.sol";

interface IMemberShip {
        struct UserProfil {
        address owner;
        uint256 experience;
        uint256 questAccepted;
        uint256 questCompleted;
        uint256 daoProposalCreated;
        uint256 daoProposalCreatedAccepted;
        uint256 daoProposalVoted;
        uint256 challengeReceived;
        uint256 friendChallenged;

    }
    function updateUserProfil(uint256 _tokenId, address _user, UserProfil memory _newProfil) external returns(UserProfil memory);
    function isOwnerOf(address _user, uint256 _tokenId) external view returns (bool);
}

contract TwitterQuest is ReentrancyGuard, AccessControl {
    using SafeERC20 for IERC20;
    using Address for address;

    address[] public participants;
    address[] public winners;
    address public lessAddress;
    address public memberShipAddress;
    address public adminAddress;
    address public contestEntryToken;
    uint256 winnersFunding;

    uint256 public entryCost;
    uint256 public lessReward;
    uint256 public fees;
    uint256 public startPeriod;
    uint256 public endPeriod;
    uint256 public delayPeriod;

    mapping(address => uint256) public poolBalance;
    mapping(address => mapping(address => uint256)) public userPoolShares;

    mapping(address => uint256) public questBalance;
    mapping(address => UserData) public userTwitterData;
    mapping(address => bool) public waitingList;
    mapping(address => bool) public hasBeenSubscribed;
    address[] public waitingListIndex;
    mapping(address => bool) public listedToken;

    struct UserData {
        address tokenDeposited;
        uint256 tokenId;
        uint256 initialFunds;
        uint256 weeklyGoalAverage;
        bool hasWin;
    }

    constructor(address _gnosis, address _oracle) {
        _grantRole(DEFAULT_ADMIN_ROLE, _gnosis);
        _grantRole(DEFAULT_ADMIN_ROLE, _oracle);
        _grantRole(DEFAULT_ADMIN_ROLE, address(this));
        adminAddress = _gnosis;

    }

    function initialize(
        uint256 _entryCost, 
        uint256 _fees, 
        uint256 _delayPeriod, 
        address _token, 
        address _memberShipAddress,
        address _lessAddress
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        entryCost = _entryCost;
        fees = _fees;
        listedToken[_token] = true;
        contestEntryToken = _token;
        memberShipAddress = _memberShipAddress;
        lessAddress = _lessAddress;
        if(_delayPeriod == 1) {
            delayPeriod = 30 days;
        } else {
            delayPeriod = _delayPeriod;
        }

        emit Initialized(_entryCost, _fees, _delayPeriod, _token, _memberShipAddress);
    }



    function registerToWaitingList() public returns (bool) {
        require(
            userPoolShares[msg.sender][contestEntryToken] >= entryCost,
            "Not Enought Contest Coins In Pool Balance To Join The Waiting List"
        );
        if(!hasBeenSubscribed[msg.sender]) {

            waitingList[msg.sender] = true;
            waitingListIndex.push(msg.sender);
            hasBeenSubscribed[msg.sender] = true; // Still used ? DB Average ?
            emit NewMemberRegisterToWaitingList(msg.sender, block.timestamp);
            return waitingList[msg.sender];
        } else {
            waitingList[msg.sender] = true;
            emit NewMemberRegisterToWaitingList(msg.sender, block.timestamp);
            return waitingList[msg.sender];
        }
    }


    function supplyToPool(
        address _token,
        uint256 _amount 
    ) external payable nonReentrant returns(uint256) {
        require(listedToken[_token], "Token not supported (yet ?)");
        poolBalance[_token] = poolBalance[_token] + _amount;
        userPoolShares[msg.sender][_token] = userPoolShares[msg.sender][_token] + _amount;
        IERC20(_token).transferFrom(msg.sender, address(this), _amount);
        emit SupplyToPool(msg.sender, _token, _amount, block.timestamp);
        return userPoolShares[msg.sender][_token];
    }

    function withdrawFromPool(
        uint256 _amount, 
        address _token
    ) public payable nonReentrant returns(uint256) {
        require(listedToken[_token], "Token not supported (yet ?)");
        require(
            userPoolShares[msg.sender][_token] >= _amount &&
                poolBalance[_token] >= _amount,
            "Not Enought Funds Availaible"
        );
        poolBalance[_token] -= _amount;
        userPoolShares[msg.sender][_token] -= _amount;
        IERC20(_token).safeTransfer(msg.sender, _amount);
        emit WithdrawFromPool(msg.sender, _token, _amount, block.timestamp);
        return userPoolShares[msg.sender][_token];
    }
    //--------- Restricted ---------//

    function lockEntryFunds(
        address[] memory _user,
        uint256[] memory _userSubscribeIndexId,
        uint256[] memory _userTokenId,
        uint256[] memory _amount,
        uint256[] memory _weeklyAverage,
        address[] memory _token
    ) public payable onlyRole(DEFAULT_ADMIN_ROLE) {
        for (uint256 i = 0; i < _user.length; i++) {
            // require(isOwnerOf(_user[i], _userTokenId[i]), "Not Member");
            if(userPoolShares[_user[i]][_token[i]] >= _amount[i] 
                // && poolBalance[_token[i]] >= _amount[i],
                ) {
            require(_amount[i] >= entryCost);

            UserData storage td = userTwitterData[_user[i]];
            td.initialFunds = _amount[i];
            td.tokenDeposited = _token[i];
            td.weeklyGoalAverage = _weeklyAverage[i];
            questBalance[_token[i]] = questBalance[_token[i]] + _amount[i];
            poolBalance[_token[i]] = poolBalance[_token[i]] - _amount[i];
            userPoolShares[_user[i]][_token[i]] = userPoolShares[_user[i]][_token[i]] - _amount[i];
            participants.push(_user[i]);
            emit NewMemberSubscribeToQuest(_user[i], _amount[i], _weeklyAverage[i], _token[i], block.timestamp);
            } else {
                waitingList[_user[i]] = false;
                if(_userSubscribeIndexId[i] != waitingListIndex.length) {
                    waitingListIndex[_userSubscribeIndexId[i]] = waitingListIndex[waitingListIndex.length - 1];
                }
                waitingListIndex.pop();

            }
        }
    }

    function updateUserTwitterData(
        address _user, 
        bool _hasWin
    ) external onlyRole(DEFAULT_ADMIN_ROLE) returns (UserData memory) {
        // Todo : add verif user = participants ?
        // require(msg.sender == adminAddress, "Not Allowed");
        UserData storage td = userTwitterData[_user];
        td.hasWin = _hasWin;
        // td = _newData;
        // handle pointer way ?
        emit NewWinnerUpdated(_user, block.timestamp);
        return userTwitterData[_user];
    }

    // determine who has win and distribute funds + start new period
    function newCycle(
        address _token
    ) public payable onlyRole(DEFAULT_ADMIN_ROLE) {
        // require(block.timestamp > endPeriod);
        uint256 totalRewards = questBalance[_token] - fees;

        for (uint256 i = 0; i < participants.length; i++) {
            UserData storage td = userTwitterData[participants[i]];

            if (td.hasWin) {
                winners.push(participants[i]);
                // winnersFunding += td.initialFunds;
            }
            // else { delete userTwitterData[participants[i]]; } delete only losers, allow to determine winner prize before deletion
            delete userTwitterData[participants[i]];
        }

        delete participants;
        if(winners.length > 0) {
            uint256 rewardAmount = totalRewards / winners.length;
            for (uint256 x = 0; x < winners.length; x++) {
                IMemberShip mb = IMemberShip(memberShipAddress);
                userPoolShares[winners[x]][_token] = userPoolShares[winners[x]][_token] + rewardAmount;
                questBalance[_token] = questBalance[_token] - rewardAmount;
                poolBalance[_token] = poolBalance[_token] + rewardAmount;

                IMemberShip.UserProfil memory imb;
                imb.experience = imb.experience + 10;
                imb.questAccepted = imb.questAccepted + 1;
                imb.questCompleted =  imb.questCompleted + 1;


                mb.updateUserProfil(userTwitterData[winners[x]].tokenId, winners[x], imb);

                if(IERC20(lessAddress).balanceOf(address(this)) > lessReward) {
                    IERC20(lessAddress).transfer(winners[x], lessReward);
                }

            }
            delete winners;

        }
        startPeriod = block.timestamp;
        endPeriod = block.timestamp + delayPeriod;


    }

        //--------- Getter / Setter ---------//

    function isOwnerOf(
        address _user, 
        uint256 _tokenId
        ) public view returns (bool) {
        return IMemberShip(memberShipAddress).isOwnerOf(_user, _tokenId);
    }


    function getAllParticipants() public view returns (address[] memory) {
        return participants;
    }

    function getAllSubscribed() public view returns (address[] memory) {
        return waitingListIndex;
    }

    function getUserWaitingListId(address _user) public view returns(uint256 i) {
        for(i = 0; i < waitingListIndex.length; i++) {
            if (_user == waitingListIndex[i]) {
                return i;
            }
        }
    }

    function setEntryCost(uint256 _newPrice) public onlyRole(DEFAULT_ADMIN_ROLE) returns(uint256) {
        return entryCost = _newPrice;
    }

    function setFees(uint256 _newPrice) public onlyRole(DEFAULT_ADMIN_ROLE) returns(uint256) {
        return fees = _newPrice;
    }

    function setDelayPeriod(uint256 _newPeriod) public onlyRole(DEFAULT_ADMIN_ROLE) returns(uint256) {
        return delayPeriod = _newPeriod;
    }

    function setEndPeriod(uint256 _newPeriod) public onlyRole(DEFAULT_ADMIN_ROLE) returns(uint256) {
        if(_newPeriod == 0) {
            return endPeriod = block.timestamp;
        } else {
            return endPeriod = _newPeriod;
        }
    }

    function setActualQuestToken(address _actualToken) public onlyRole(DEFAULT_ADMIN_ROLE) returns(address) {
        require(listedToken[_actualToken], "Token Not Listed !");
        return contestEntryToken = _actualToken;
    }

    function listNewToken(address _token) public onlyRole(DEFAULT_ADMIN_ROLE) returns(bool) {
        return listedToken[_token] = true;
    }

    function deleteToken(address _token) public onlyRole(DEFAULT_ADMIN_ROLE) returns(bool) {
        return listedToken[_token] = false;
    }

    function setLessAddress(address _token) public onlyRole(DEFAULT_ADMIN_ROLE) returns(address) {
        return lessAddress = _token;
    }

    function setLessReward(uint256 _newReward) public onlyRole(DEFAULT_ADMIN_ROLE) returns(uint256) {
        return lessReward = _newReward;
    }

    function setMemberShipAddress(address _membership) public onlyRole(DEFAULT_ADMIN_ROLE) returns(address) {
        return memberShipAddress = _membership;
    }

    //--------- Events ---------//


    event SupplyToPool(address indexed _user, address indexed _token, uint256 _amount, uint256 _date);
    event WithdrawFromPool(address indexed _user, address indexed _token, uint256 _amount, uint256 _date);
    event NewMemberRegisterToWaitingList(address indexed _user, uint256 _date);
    event NewMemberSubscribeToQuest(address indexed _user, uint256 _amount, uint256 _weeklyAverage, address _token, uint256 _date);
    event NewWinnerUpdated(address indexed _user, uint256 _date);
    event NewCycle(uint256);
    event Initialized(uint256 _entryCost, uint256 _fees, uint256 _delayPeriod, address indexed _token, address indexed _memberShipAddress);

    receive() external payable {}

}
