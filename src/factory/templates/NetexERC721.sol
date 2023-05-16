pragma solidity 0.8.17;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuardUpgradeable} from "openzeppelin-contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
// import {IERC721Metadata} from "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import {ERC721ACloneable} from "./ERC721ACloneable.sol";

contract NetexERC721 is
    ERC721ACloneable,
    ReentrancyGuardUpgradeable,
    Ownable
{
    error MinterIsZeroAddress();
    error MaxSupplyReached();
    error NotMinter();
    
    event MinterUpdated(address oldMinter, address newMinter);

    address public minter;
    uint256 public maxSupply;
    string tokenBaseUri;

    function initialize(
        string memory __name,
        string memory __symbol,
        address _minter,
        address _initialOwner,
        bytes calldata
    ) external initializer {
        __ERC721ACloneable__init(__name, __symbol);
        __ReentrancyGuard_init();
        _transferOwnership(_initialOwner);
        _setMinter(_minter);
    }

    function configure(
        uint256 _maxSupply,
        string memory _tokenBaseUri
    ) external onlyOwner {
        maxSupply = _maxSupply;
        tokenBaseUri = _tokenBaseUri;
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
        if (_totalMinted() + quantity > maxSupply) revert MaxSupplyReached();

        _safeMint(to, quantity);
    }

    /**
     * @notice Returns the base URI for token metadata.
     */
    function baseURI() external view returns (string memory) {
        return _baseURI();
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return tokenBaseUri;
    }

}
