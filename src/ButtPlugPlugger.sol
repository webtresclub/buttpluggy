// SPDX-License-Identifier: TODO
pragma solidity 0.8.19;

import {IUwU} from "./IUwU.sol";

contract ButtPlugPlugger {
    /// @dev The difficulty is the number of 0s that the hash of the address and the nonce must have
    ///      5 means 0x00000, anf im expecting to take a few secs to find a nonce
    uint256 public constant DEFAULT_DIFFICULTY = 5;
    uint256 public constant MAX_DIFFICULTY = 32;
    /// @dev The maximum number of UwU that can be minted
    uint256 public constant MAX_SUPPLY = 10000;

    /// @dev We have to know when the collection started to calculate the difficulty using VERGA
    /// VERGA is inspired https://www.paradigm.xyz/2022/08/vrgda
    uint256 public immutable collectionStart;
    IUwU public immutable UwU;

    bytes32 public salt;

    error YouHaveToGiveMeYourConsent();
    error NoMoreUwU();

    constructor(address _UwU) {
        collectionStart = block.timestamp;
        /// @dev This contract is the owner of the UwU
        UwU = IUwU(_UwU);
        salt = keccak256(abi.encodePacked(msg.sender, block.prevrandao));
    }

    /// @dev Returns the current difficulty, calculated using VERGA curve
    function currentDifficulty() public view returns (uint256) {
        uint256 tSupply = UwU.totalSupply();
        return _currentDifficulty(tSupply);
    }

    function _currentDifficulty(uint256 tSupply) private view returns (uint256) {
        unchecked {
            /// @dev We expect to mint 1 UwU per day
            uint256 delta = (block.timestamp - collectionStart) / 1 days;

            /// @dev If we have minted less than we supposed to, we are in the first phase
            if (delta < tSupply + 1) {
                return DEFAULT_DIFFICULTY;
            }

            // uint256 ret = 2 ** (tSupply - delta);
            uint256 ret = (tSupply - delta) / 10;
            if (ret < DEFAULT_DIFFICULTY) return DEFAULT_DIFFICULTY;
            if (ret > MAX_DIFFICULTY) return MAX_DIFFICULTY;
            return ret;
        }
    }

    function plugConsent(uint256 nonce) external {
        uint256 tSupply = UwU.totalSupply();
        if (tSupply > MAX_SUPPLY) revert NoMoreUwU();

        /// @dev This is inspired by the difficulty adjustment algorithm of Bitcoin    
        uint256 difficulty = _currentDifficulty(tSupply);
        bytes32 bitmask = bytes32(2 ** (4 * difficulty) - 1 << 4 * (64 - difficulty));
        
        bool canPlug = keccak256(abi.encodePacked(msg.sender, salt, nonce)) & bitmask == 0;
        if (!canPlug) revert YouHaveToGiveMeYourConsent();

        // mintear el nft
        bytes32 seed = keccak256(abi.encodePacked(msg.sender, nonce));
        uint256 _dna = dna(seed);

        salt = keccak256(abi.encodePacked(msg.sender, block.prevrandao));
        /// @dev if _dna is already minted, this will revert
        UwU.plug(msg.sender, _dna);
    }

    /// @dev Based on a seed will return a DNA
    /// @param seed The seed to calculate the DNA
    /// @return The DNA
    function dna(bytes32 seed) public pure returns (uint256) {
        /// seed&0x00000000ffff % Number of bodies = Body
        uint256 body = (uint256(seed) & 0x00000000ffff) % 10;
        /// seed&0x0000ffff0000 % Number of eyes   = Eyes
        uint256 eyes = ((uint256(seed) & 0x0000ffff0000) >> 16) % 10;
        /// seed&0xffff00000000 % Number of mouths = Mouth
        uint256 mouth = ((uint256(seed) & 0xffff00000000 >> 32)) % 10;
        // background
        // etc
        // etc

        return body << 16 | eyes << 8 | mouth;
    }
}
