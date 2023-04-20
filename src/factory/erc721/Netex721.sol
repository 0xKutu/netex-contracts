pragma solidity 0.8.17;

import {ERC721ACloneable} from "../templates/ERC721ACloneable.sol";

contract NetexERC721 is ERC721ACloneable {
    function initialize(
        string memory __name,
        string memory __symbol,
        address minter,
        address initialOwner,
        bytes calldata data
    ) external initializer {
        __ERC721ACloneable__init(__name, __symbol);
    }
}
