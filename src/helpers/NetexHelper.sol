// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC721 {
    function name() external view returns (string memory _name);
    function symbol() external view returns (string memory _symbol);
    function tokenURI(uint256 _tokenId) external view returns (string memory);
    function totalSupply() external view returns (uint256);
    function ownerOf(uint256 _tokenId) external view returns (address);
}

contract ERC721Helper {

    struct CollectionInfo {
        string name;
        string symbol;
        // uint256 maxSupply;
        uint256 totalSupply;
        // NFT[] list;
    }

    struct TokenMetadata {
        uint256 id;
        address owner;
        string uri;
    }

    function getCollectionBaseInfo(address tokenAddr) public view returns(CollectionInfo memory collection) {
        IERC721 iToken = IERC721(tokenAddr);
        collection = CollectionInfo({
            name: iToken.name(),
            symbol: iToken.symbol(),
            totalSupply: iToken.totalSupply()
        });
    }

    function getTokenMetadataList(address tokenAddr, uint256 from, uint256 to) public view returns(TokenMetadata[] memory) {
        IERC721 iToken = IERC721(tokenAddr);

        uint256 total = to-from;
        TokenMetadata[] memory tokens = new TokenMetadata[](total);
        
        uint256 i;
        for(; i < total;) {
            uint256 tokenId = from+i;
            string memory uri;
            address owner;
            try iToken.tokenURI(tokenId) returns (string memory _uri) {
                uri = _uri;
                owner = iToken.ownerOf(tokenId);
            } catch {
                // catch failing revert() and require()
            }

            tokens[i] = TokenMetadata({
                id: tokenId,
                owner: owner,
                uri: uri
            });

            unchecked {
                ++i;
            }
        }
        return tokens;
    }

    function getNFTDetail(
        address tokenAddr, uint256 tokenId
    ) public view returns (
        CollectionInfo memory collectionInfo, TokenMetadata memory metadata
    ) {
        IERC721 iToken = IERC721(tokenAddr);
       
        collectionInfo.name = iToken.name();
        collectionInfo.symbol = iToken.symbol();
        collectionInfo.totalSupply = iToken.totalSupply();
        metadata.id = tokenId;
        metadata.uri = iToken.tokenURI(tokenId);
        metadata.owner = iToken.ownerOf(tokenId);
    }

    function getTokensMetadata(address tokenAddr, uint256[] calldata ids) public view returns(TokenMetadata[] memory metadata) {
        IERC721 iToken = IERC721(tokenAddr);

        uint256 i;
        for(; i < ids.length;) {
            uint256 tokenId = ids[i];
            metadata[i].id = tokenId;
            metadata[i].uri = iToken.tokenURI(tokenId);
            metadata[i].owner = iToken.ownerOf(tokenId);
        }

    }

}