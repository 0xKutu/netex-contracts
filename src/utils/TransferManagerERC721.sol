// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import {ITransferManagerNFT} from "../interfaces/ITransferManagerNFT.sol";
import {LibERC721LazyMint} from "../libraries/LibERC721LazyMint.sol";
import {IERC721LazyMint} from "../interfaces/IERC721LazyMint.sol";

/**
 * @title TransferManagerERC721
 * @notice It allows the transfer of ERC721 tokens.
 */
contract TransferManagerERC721 is ITransferManagerNFT {
    address public immutable NETEX_EXCHANGE;

    /**
     * @notice Constructor
     * @param _netexExchange address of the LooksRare exchange
     */
    constructor(address _netexExchange) {
        NETEX_EXCHANGE = _netexExchange;
    }

    // modifier onlyExchange() {

    // }

    /**
     * @notice Transfer ERC721 token
     * @param collection address of the collection
     * @param from address of the sender
     * @param to address of the recipient
     * @param tokenId tokenId
     * @dev For ERC721, amount is not used
     */
    function transferNonFungibleToken(
        address collection,
        address from,
        address to,
        uint256 tokenId,
        uint256
    ) external override {
        require(msg.sender == NETEX_EXCHANGE, "Transfer: Only Netex Exchange");
        // https://docs.openzeppelin.com/contracts/2.x/api/token/erc721#IERC721-safeTransferFrom
        IERC721(collection).safeTransferFrom(from, to, tokenId);
    }

    /**
     * @notice Transfer ERC721 token
     * @param collection address of the collection
     * @param from address of the sender
     * @param to address of the recipient
     * @param tokenId tokenId
     * @dev For ERC721, amount is not used
     */
    function transferNonFungibleToken(
        address collection,
        address from,
        address to,
        uint256 tokenId,
        uint256,
        bytes calldata data
    ) external override {
        require(msg.sender == NETEX_EXCHANGE, "Transfer: Only Netex Exchange");
        // https://docs.openzeppelin.com/contracts/2.x/api/token/erc721#IERC721-safeTransferFrom
        if(data.length > 0) {
            LibERC721LazyMint.Mint721Data memory mintData = abi.decode(data, (LibERC721LazyMint.Mint721Data));
            require(mintData.tokenId == tokenId, "Transfer: Wrong token id");
            IERC721LazyMint(collection).transferFromOrMint(mintData, from, to);
        } else {
            IERC721(collection).safeTransferFrom(from, to, tokenId);
        }
    }

}