pragma solidity ^0.8.17;

import {ERC721URIStorage} from "./erc721/ERC721URIStorage.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
// import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import {IERC1271} from "./IERC1271.sol";
import {LibSignature} from "./libraries/LibSignature.sol";
import {LibERC721LazyMint} from "../libraries/LibERC721LazyMint.sol";
import {ERC2981} from "./erc2981/ERC2981.sol";
import {ERC721Cloneable} from "./erc721/ERC721Cloneable.sol";

import {console} from "forge-std/console.sol";

contract NetexERC721Collection is
    ERC721URIStorage,
    Ownable,
    ReentrancyGuard,
    // ReentrancyGuardUpgradeable,
    EIP712,
    ERC2981
{
    error MinterIsZeroAddress();
    error MaxSupplyReached();
    error NotMinter();
    error MaxSupply();

    event MinterUpdated(address oldMinter, address newMinter);

    string private constant SIGNING_DOMAIN = "NetexLazyMint";
    string private constant SIGNATURE_VERSION = "1";
    bytes32 public immutable DOMAIN_SEPARATOR;

    // address public minter;
    uint256 public maxSupply;

    constructor(
        string memory __name,
        string memory __symbol,
        address _initialOwner,
        bytes memory /* data */
    ) EIP712(SIGNING_DOMAIN, SIGNATURE_VERSION) {
        __ERC721Cloneable__init(__name, __symbol);

        // __ReentrancyGuard_init();
        _transferOwnership(_initialOwner);
        // _setMinter(_minter);

        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                0x8b73c3c69bb8fe3d512ecc4cf759cc79239f7b179b0ffacaa9a75d522b39400f, // keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)")
                0xceb305597ad05755de545c066f1bf0d269b0d0955bf11787ae1a284c0ad3b723, // keccak256("ERC721LazyTemplate")
                0xc89efdaa54c0f20c7adf612882df0950f5a951637e0307cdcb4c672f298b8bc6, // keccak256(bytes("1")) for versionId = 1
                block.chainid,
                address(this)
            )
        );
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721Cloneable, ERC2981) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    // function configure(
    //     uint256 _maxSupply,
    //     string memory _baseUri
    // ) external onlyOwner {
    //     if (_maxSupply > 0) {
    //         _setMaxSupply(_maxSupply);
    //     }
    //     if (bytes(_baseUri).length != 0) {
    //         _setBaseUri(_baseUri);
    //     }
    // }

    function setMaxSupply(uint256 _newMaxSupply) external onlyOwner {
        _setMaxSupply(_newMaxSupply);
    }

    function _setMaxSupply(uint256 _newMaxSupply) internal {
        maxSupply = _newMaxSupply;
    }

    // function updateMinter(address _minter) external onlyOwner {
    //     _setMinter(_minter);
    // }

    // function _setMinter(address _minter) internal {
    //     if (_minter == address(0)) revert MinterIsZeroAddress();

    //     address oldMinter = minter;
    //     minter = _minter;

    //     emit MinterUpdated(oldMinter, minter);
    // }

    // function mint(address to, uint256 tokenId) external nonReentrant {
    //     if (msg.sender != minter) revert NotMinter();
    //     // if (_totalMinted() + quantity > maxSupply) revert MaxSupplyReached();

    //     _safeMint(to, tokenId);
    // }

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
                    DOMAIN_SEPARATOR
                ),
                "Signature: Invalid"
            );
        }

        _safeMint(to, data.tokenId);
        _setTokenRoyalty(data.tokenId, data.creator, data.royalty);
        _setTokenURI(data.tokenId, data.tokenURI);
    }
}
