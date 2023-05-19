pragma solidity ^0.8.17;

library LibERC721LazyMint {

    struct Mint721Data {
        uint256 tokenId;
        string tokenURI;
        address creator;
        uint96 royalty;
        bytes signature;
    }

    bytes32 public constant MINT_AND_TRANSFER_TYPEHASH =
        keccak256(
            "Mint721Data(uint256 tokenId,string tokenURI,address creator,uint256 royalty)"
        );

    function hash(Mint721Data memory data) internal pure returns (bytes32) {
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
}
