// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

// import {OrderTypes} from "../../src/libraries/OrderTypes.sol";
import {LibERC721LazyMint} from "../../src/libraries/LibERC721LazyMint.sol";

contract LazyMintSigUtils {

    bytes32 public constant MINT_AND_TRANSFER_HASH =
        keccak256(
            "Mint721Data(uint256 tokenId,string tokenURI,address creator,uint256 royalty)"
        );

    bytes32 internal immutable DOMAIN_SEPARATOR;

    constructor(bytes32 _DOMAIN_SEPARATOR) {
        DOMAIN_SEPARATOR = _DOMAIN_SEPARATOR;
    }

    // compute the hash of a mint data
    function hash(LibERC721LazyMint.Mint721Data memory data) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256(
                        "Mint721Data(uint256 tokenId,string tokenURI,address creator,uint256 royalty)"
                    ),
                    data.tokenId,
                    keccak256(bytes(data.tokenURI)),
                    data.creator,
                    data.royalty
                )
            );
    }

    // computes the hash of the fully encoded EIP-712 message for the domain, which can be used to recover the signer
    function getTypedDataHash(
        LibERC721LazyMint.Mint721Data memory data
    ) public view returns (bytes32) {
        return
            keccak256(
                abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR, hash(data))
            );
    }
}
