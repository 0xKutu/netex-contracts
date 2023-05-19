pragma solidity 0.8.17;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuardUpgradeable} from "openzeppelin-contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
// import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
// import {IERC721Metadata} from "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import {ERC721ContractMetadataCloneable} from "./ERC721ContractMetadataCloneable.sol";

contract ERC721NetexDrop is
    ERC721ContractMetadataCloneable,
    ReentrancyGuardUpgradeable
{
    error MinterIsZeroAddress();
    error MaxSupplyReached();
    error NotMinter();

    event MinterUpdated(address oldMinter, address newMinter);

    address public minter;

    constructor() {}

    function initialize(
        string memory __name,
        string memory __symbol,
        address _initialOwner,
        bytes calldata
    ) external {
        __ERC721ACloneable__init(__name, __symbol);
        __ReentrancyGuard_init();
        _transferOwnership(_initialOwner);
    }

    function configure(
        uint256 _maxSupply,
        string memory _baseUri,
        string memory _contractURI
    ) external onlyOwner {
        if(_maxSupply > 0) {
            this.setMaxSupply(_maxSupply);
        }
        if(bytes(_baseUri).length != 0) {
            this.setBaseURI(_baseUri);
        }
        if (bytes(_contractURI).length != 0) {
            this.setContractURI(_contractURI);
        }
    }

    function updateMinter(address _minter) external onlyOwner {
        _setMinter(_minter);
    }

    function _setMinter(address _minter) internal {
        if (_minter == address(0)) revert MinterIsZeroAddress();

        address oldMinter = minter;
        minter = _minter;

        emit MinterUpdated(oldMinter, minter);
    }

    function mint(address to, uint256 quantity) external nonReentrant {
        if (msg.sender != minter) revert NotMinter();
        if (_totalMinted() + quantity > maxSupply()) revert MaxSupplyReached();

        _safeMint(to, quantity);
    }
}
