// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract MemberShip is ERC721, ERC721URIStorage, Pausable, AccessControl {
    using Counters for Counters.Counter;

    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    Counters.Counter private _tokenIdCounter;

    mapping(address => mapping(uint256 => bool)) public isOwnerOf;
    mapping(uint256 => mapping(address => UserProfil)) public userProfil;
    mapping(address => bool) public isOwner;
    uint256 public maxCap;

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

    constructor(address _gnosis, address _oracle) ERC721("PoL-Membership", "POLM") {
        _grantRole(DEFAULT_ADMIN_ROLE, _gnosis);
        _grantRole(DEFAULT_ADMIN_ROLE, _oracle);
        _grantRole(PAUSER_ROLE, _gnosis);
        _grantRole(MINTER_ROLE, _gnosis);
        maxCap = 1;
    }

    function updateUserProfil(
        uint256 _tokenId, 
        address _user, 
        UserProfil memory _newProfil
    ) external onlyRole(DEFAULT_ADMIN_ROLE) returns(UserProfil memory) {
        UserProfil storage up = userProfil[_tokenId][_user];
        if(_newProfil.experience > 0) {
            up.experience = _newProfil.experience;
        }
        if(_newProfil.questAccepted > 0) {
            up.questAccepted = _newProfil.questAccepted;
        }
        if(_newProfil.questCompleted > 0) {
            up.questCompleted = _newProfil.questCompleted;
        }
        if(_newProfil.daoProposalCreated > 0) {
            up.daoProposalCreated = _newProfil.daoProposalCreated;
        }
        if(_newProfil.daoProposalCreatedAccepted > 0) {
            up.daoProposalCreatedAccepted = _newProfil.daoProposalCreatedAccepted;
        }
        if(_newProfil.daoProposalVoted > 0) {
            up.daoProposalVoted = _newProfil.daoProposalVoted;
        }
        if(_newProfil.challengeReceived > 0) {
            up.challengeReceived = _newProfil.challengeReceived;
        }
        if(_newProfil.friendChallenged > 0) {
            up.friendChallenged = _newProfil.friendChallenged;
        }
        return userProfil[_tokenId][_user];
    }   

    function isUserOwnerOf(address _user, uint256 _tokenId) external view returns (bool) {
        return isOwnerOf[_user][_tokenId];
    }

    function setMaxCap(uint256 _newMaxCap) public onlyRole(DEFAULT_ADMIN_ROLE) returns (uint256) {
        return maxCap = _newMaxCap;
    }

    function pause() public onlyRole(DEFAULT_ADMIN_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(DEFAULT_ADMIN_ROLE) {
        _unpause();
    }

    function safeMint(address to, string memory uri) public onlyRole(MINTER_ROLE) {
        if(
            !hasRole(DEFAULT_ADMIN_ROLE, msg.sender) 
            && !hasRole(DEFAULT_ADMIN_ROLE, to)
        ) {
            require(maxCap >= balanceOf(msg.sender), "Receiver Has Reach Max Limit");
        }
        uint256 tokenId = _tokenIdCounter.current();
        UserProfil storage up = userProfil[tokenId][to];

        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, uri);
        isOwnerOf[to][tokenId] = true;
        isOwner[to] = true;
        up.owner = to; 
        
        if(!hasRole(DEFAULT_ADMIN_ROLE, msg.sender)) {
            _revokeRole(MINTER_ROLE, msg.sender);
        }
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        whenNotPaused
        override
    {
        if(!hasRole(DEFAULT_ADMIN_ROLE, to)) {
            require(maxCap >= balanceOf(msg.sender), "Receiver Has Reach Max Limit");
        }
        userProfil[tokenId][to].owner = to;
        isOwner[from] = false;
        isOwnerOf[from][tokenId] = false;
        isOwner[to] = true;
        isOwnerOf[to][tokenId] = true;
        super._beforeTokenTransfer(from, to, tokenId);
    }

    // The following functions are overrides required by Solidity.

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        userProfil[tokenId][msg.sender].owner = 0x0000000000000000000000000000000000000000;
        isOwnerOf[msg.sender][tokenId] = false;
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}