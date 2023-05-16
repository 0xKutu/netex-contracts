// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

// import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "../libraries/LibERC721LazyMint.sol";

interface IERC721LazyMint /*is IERC721*/ {

    function mintAndTransfer(
        LibERC721LazyMint.Mint721Data memory data,
        address to
    ) external;

    function transferFromOrMint(
        LibERC721LazyMint.Mint721Data memory data,
        address from,
        address to
    ) external;
}