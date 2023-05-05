// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "../../src/IUwU.sol";

contract MockUwU is IUwU {
    string public name = "Buttpluggy";
    string public symbol = "UwU";
    address public immutable owner = msg.sender;


    mapping(uint256 seed => address user) public seedToUser;
    mapping(address user => uint256 seed) public userToSeed;
    uint256 public totalSupply;


    function plug(address user, uint256 genSeed) external {
        ++totalSupply;
        seedToUser[genSeed] = user;
        userToSeed[user] = genSeed;
    }

    function tokenURI(uint256) external pure returns (string memory) {
        return "";
    }

}
