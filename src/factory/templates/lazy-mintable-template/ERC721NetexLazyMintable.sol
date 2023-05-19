pragma solidity ^0.8.17;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
// import {ReentrancyGuardUpgradeable} from "openzeppelin-contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {ERC721URIStorage} from "./erc721/ERC721URIStorage.sol";
import {ERC721Cloneable} from "./erc721/ERC721Cloneable.sol";
// import "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import {LibERC721LazyMint} from "../../../libraries/LibERC721LazyMint.sol";
import {IERC1271} from "../../../interfaces/IERC1271.sol";
import {LibSignature} from "../../libraries/LibSignature.sol";
import {ERC2981} from "../../erc2981/ERC2981.sol";

import {console} from "forge-std/console.sol";

contract ERC721NetexLazyMintable is
    ERC721URIStorage,
    Ownable,
    ReentrancyGuard,
    // ReentrancyGuardUpgradeable,
    ERC2981
{

    struct Settings {
        bool initialized;
        bool isPrivate;
    }

    Settings settings;
    // bool isPrivate;

    error MinterIsZeroAddress();
    error MaxSupplyReached();
    error NotMinter();
    error MaxSupply();
    error ERC721AlreadyInitialized();

    event MinterUpdated(address oldMinter, address newMinter);

    function __ERC721LazyTemplate_init(
        string memory __name,
        string memory __symbol,
        address _initialOwner,
        bytes memory /* data */
    ) external {
        if(settings.initialized) {
            revert ERC721AlreadyInitialized();
        }
        settings.initialized = true;
        __ERC721Cloneable__init(__name, __symbol);
        // __ReentrancyGuard_init();
        _transferOwnership(_initialOwner);
        // _setMinter(_minter);
    }


    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721Cloneable, ERC2981) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function transferFromOrMint(
        LibERC721LazyMint.Mint721Data memory data,
        address from,
        address to
    ) external nonReentrant {
        if (_exists(data.tokenId)) {
            safeTransferFrom(from, to, data.tokenId);
        } else {
            mintAndTransfer(data, to);
        }
    }

    function mintAndTransfer(
        LibERC721LazyMint.Mint721Data memory data,
        address to
    ) public virtual {
        if (settings.isPrivate){
            require(owner() == data.creator, "minter is not the owner");
        }

        address minter = address(uint160(data.tokenId >> 96));
        address sender = _msgSender();

        require(minter == data.creator, "tokenId incorrect");
        // require(data.creators.length == data.signatures.length);
        require(
            minter == sender || isApprovedForAll(minter, sender),
            "ERC721: transfer caller is not owner nor approved"
        );

        address creator = data.creator;
        if (creator != sender) {
            require(
                LibSignature.verify(
                    LibERC721LazyMint.hash(data),
                    creator,
                    data.signature,
                    DOMAIN_SEPARATOR()
                ),
                "Signature: Invalid"
            );
        }

        _safeMint(to, data.tokenId);
        _setTokenRoyalty(data.tokenId, data.creator, data.royalty);
        _setTokenURI(data.tokenId, data.tokenURI);
    }

    function DOMAIN_SEPARATOR() public view returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    0x8b73c3c69bb8fe3d512ecc4cf759cc79239f7b179b0ffacaa9a75d522b39400f, // keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)")
                    0xf89f342dc369acb8230da6654cf69befe5591ff47d9920290a4b14b3acd25bfa, // keccak256("ERC721LazyTemplate")
                    0xc89efdaa54c0f20c7adf612882df0950f5a951637e0307cdcb4c672f298b8bc6, // keccak256(bytes("1")) for versionId = 1
                    block.chainid,
                    address(this)
                )
            );
    }

}
