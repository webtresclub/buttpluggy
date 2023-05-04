// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IUwU {
    function totalSupply() external view returns (uint256);
    function plug(address user, uint256 genSeed) external;
}
