// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import {GasSnapshot} from "forge-gas-snapshot/GasSnapshot.sol";
import "../src/ButtplugPlugger.sol";
import "./mocks/MockUwU.sol";

contract ButtplugPluggerTest is Test, GasSnapshot {
    ButtplugPlugger public bplug;

    function setUp() public {
        bplug = new ButtplugPlugger(address(new MockUwU()));
        snapSize("ButtplugPluggerV1", address(bplug));
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
        snapStart("MintWithPlugConsentV1");
        bplug.plugConsent(CALCULATED_SEED);
        snapEnd();
    }
}
