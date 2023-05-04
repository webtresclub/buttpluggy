// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/ButtPlugPlugger.sol";

contract ButtplugTest is Test {
    ButtPlugPlugger public bplug;

    function setUp() public {
        bplug = new ButtPlugPlugger(address(new MockUwU()));
    }

    function testCurveVERGA() public {
        assertEq(bplug.currentDifficulty(), 5);
    }

    function testSimpleconsense() public {
        /// @dev please see crack-poc/index.js
        uint256 CALCULATED_SEED = 441005;

        assertEq(bplug.salt(), 0x398fa36d091cdce6844aaf66e84de736e0849a052fd5fdb8b5c60f13c0506b5a, "salt is the expected");
        // user = 0x6CA6d1e2D5347Bfab1d91e883F1915560e09129D
        address user = makeAddr("user");
        console.logBytes(abi.encodePacked(msg.sender, bplug.salt(), CALCULATED_SEED));
        vm.startPrank(user);
        bplug.plugConsent(CALCULATED_SEED);
    }
}

contract MockUwU is IUwU {
    mapping(uint256 seed => address user) public seedToUser;
    mapping(address user => uint256 seed) public userToSeed;
    uint256 public totalSupply;


    function plug(address user, uint256 genSeed) external {
        ++totalSupply;
        seedToUser[genSeed] = user;
        userToSeed[user] = genSeed;
    }

}
