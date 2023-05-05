// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

// source https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC721/extensions/IERC721Metadata.sol
interface IERC721Metadata {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

interface IUwU is IERC721Metadata{
    function owner() external view returns (address);
    function totalSupply() external view returns (uint256);
    function plug(address user, uint256 genSeed) external;
}
