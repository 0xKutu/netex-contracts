// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract MockERC721 is ERC721, Ownable {

    uint public tokenId;
    constructor(string memory _name, string memory _symbol) ERC721(_name, _symbol) {}

    function tokenURI(uint256) public pure virtual override returns (string memory) {}

    function mintMany(address to, uint256 amount) public virtual {
        unchecked {
        uint i;
            for(; i < amount;) {
                _mint(to, tokenId++);
                ++i;
            }
        }
    }

    function mint(address to, uint256 _tokenId) public virtual {
        _mint(to, _tokenId);
    }

    function burn(uint256 _tokenId) public virtual {
        _burn(_tokenId);
    }

    function safeMint(address to, uint256 _tokenId) public virtual {
        _safeMint(to, _tokenId);
    }

    function safeMint(
        address to,
        uint256 _tokenId,
        bytes memory data
    ) public virtual {
        _safeMint(to, _tokenId, data);
    }
}
