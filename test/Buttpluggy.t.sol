// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "foundry-huff/HuffDeployer.sol";
import {GasSnapshot} from "forge-gas-snapshot/GasSnapshot.sol";

import "../src/IUwU.sol";

contract ButtplugyTest is Test, GasSnapshot {
    IUwU public buttpluggy;

    function setUp() public {
        buttpluggy = IUwU(HuffDeployer.config().with_addr_constant("OWNER", address(this)).deploy("Buttpluggy"));
        snapSize("ButtplugyV1", address(buttpluggy));
        
    }
    function testMetadata() public {
      assertEq(buttpluggy.symbol(), "UwU");
      assertEq(buttpluggy.name(), "Buttpluggy");
    }

    function testOwnership() public {
      assertEq(buttpluggy.owner(), address(this));
    }

    

    function testSimpleconsense() public {
        
    }
}
