// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract LessToken is ERC20, Pausable, AccessControl {
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    mapping(address => bool) public isValidReceiver;
    uint256 maxSupply;

    constructor(address _gnosis, address _oracle) ERC20("Less-Token", "LESS") {
        _grantRole(DEFAULT_ADMIN_ROLE, _gnosis);
        _grantRole(DEFAULT_ADMIN_ROLE, _oracle);
        _grantRole(PAUSER_ROLE, _gnosis);
        _grantRole(MINTER_ROLE, _gnosis);

        maxSupply = 31012000;
    }

    function pause() public onlyRole(DEFAULT_ADMIN_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(DEFAULT_ADMIN_ROLE) {
        _unpause();
    }

    function addNewReceiver(address _newReceiver) public onlyRole(DEFAULT_ADMIN_ROLE) {
        isValidReceiver[_newReceiver] = true;
    }

    function deleteReceiver(address _oldReceiver) public onlyRole(DEFAULT_ADMIN_ROLE) {
        isValidReceiver[_oldReceiver] = false;
    }

    function mint(address to, uint256 amount) public onlyRole(MINTER_ROLE) {
        require( maxSupply >= (amount + totalSupply()));
        _mint(to, amount);
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount)
        internal
        whenNotPaused
        override
    {
        if(!hasRole(DEFAULT_ADMIN_ROLE, msg.sender)) {
            require(isValidReceiver[to], "Incorrect Receiver");
        }
        super._beforeTokenTransfer(from, to, amount);
    }
}