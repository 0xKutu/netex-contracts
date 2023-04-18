pragma solidity 0.8.17;

// import {Test} from "forge-std/Test.sol";
import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";

import {CurrencyManager} from "../src/CurrencyManager.sol";
import {ExecutionManager} from "../src/ExecutionManager.sol";
import {RoyaltyFeeRegistry} from "../src/fee/RoyaltyFeeRegistry.sol";
import {RoyaltyFeeManagerV1B} from "../src/RoyaltyFeeManagerV1B.sol";
import {TransferSelectorNFT} from "../src/TransferSelectorNFT.sol";
import {NetexExchange} from "../src/NetexExchange.sol";
import {TransferManagerERC721} from "../src/utils/TransferManagerERC721.sol";
import {TransferManagerERC1155} from "../src/utils/TransferManagerERC1155.sol";
import {FeeSharingSetter} from "../src/fee/FeeSharingSetter.sol";
import {StrategyAnyItemFromCollectionForFixedPriceV1B} from "../src/strategies/StrategyAnyItemFromCollectionForFixedPriceV1B.sol";
import {StrategyPrivateSale} from "../src/strategies/StrategyPrivateSale.sol";
import {StrategyStandardSaleForFixedPriceV1B} from "../src/strategies/StrategyStandardSaleForFixedPriceV1B.sol";

import {MockERC721} from "./mocks/MockERC721.sol";
import {MockERC20} from "./mocks/MockERC20.sol";
import {WETH} from "../src/tokens/WETH.sol";

contract BaseTest is Test {
    address internal constant ZERO_ADDRESS = address(0x0);
    address internal constant ETH_ADDRESS = address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);

    // CORE Contracts
    CurrencyManager public currencyManager;
    ExecutionManager public executionManager;
    RoyaltyFeeRegistry public royaltyFeeRegistry;
    RoyaltyFeeManagerV1B public royaltyFeeManager;
    TransferManagerERC721 public transferManagerERC721;
    TransferManagerERC1155 public transferManagerERC1155;
    TransferSelectorNFT public transferSelectorNFT;
    FeeSharingSetter public feeSharingSetter;
    NetexExchange public exchange;
    StrategyAnyItemFromCollectionForFixedPriceV1B
        public anyItemFromCollectionForFixedPriceStrg;
    StrategyPrivateSale public privateSaleStrg;
    StrategyStandardSaleForFixedPriceV1B public standartSaleForFixedPriceStrg;
    WETH public weth;

    // MOCKS
    MockERC721 public nft1;
    MockERC721 public nft2;
    MockERC721 public nft3;
    MockERC20 public usdt;

    uint256 public alicePK;
    uint256 public bobPK;
    uint256 public evePK;

    // ACCOUNTS
    address public deployer;
    address public alice;
    address public bob;
    address public eve;
    address public protocolFeeRecipient;

    uint256 public constant ROYALTY_FEE_LIMIT = 9500;

    function setUp() public virtual {
        deployer = address(0x1234);
        protocolFeeRecipient = address(0x2345); // FeeSharingSetter

        alicePK = 0xA11CE;
        bobPK = 0xB0B;
        evePK = 0xeee;
        alice = vm.addr(alicePK);
        bob = vm.addr(bobPK);
        eve = vm.addr(evePK);

        vm.deal(alice, 100 ether);
        vm.deal(bob, 500 ether);
        vm.deal(eve, 10 ether);

        vm.label(deployer, "deployer");
        vm.startPrank(deployer);
        deal(deployer, 100 ether);

        currencyManager = new CurrencyManager();
        executionManager = new ExecutionManager();
        royaltyFeeRegistry = new RoyaltyFeeRegistry(ROYALTY_FEE_LIMIT);
        royaltyFeeManager = new RoyaltyFeeManagerV1B(
            address(royaltyFeeRegistry)
        );
        weth = new WETH();
        currencyManager.addCurrency(address(weth));

        exchange = new NetexExchange(
            address(currencyManager),
            address(executionManager),
            address(royaltyFeeManager),
            address(weth),
            address(protocolFeeRecipient)
        );

        // MANAGERS
        transferManagerERC721 = new TransferManagerERC721(address(exchange));
        transferManagerERC1155 = new TransferManagerERC1155(address(exchange));
        transferSelectorNFT = new TransferSelectorNFT(
            address(transferManagerERC721),
            address(transferManagerERC1155)
        );

        exchange.updateTransferSelectorNFT(address(transferSelectorNFT));

        assert(
            address(exchange.transferSelectorNFT()) ==
                address(transferSelectorNFT)
        );

        // STRATEGIES
        anyItemFromCollectionForFixedPriceStrg = new StrategyAnyItemFromCollectionForFixedPriceV1B();
        privateSaleStrg = new StrategyPrivateSale(0);
        standartSaleForFixedPriceStrg = new StrategyStandardSaleForFixedPriceV1B();

        executionManager.addStrategy(
            address(anyItemFromCollectionForFixedPriceStrg)
        );
        executionManager.addStrategy(address(privateSaleStrg));
        executionManager.addStrategy(address(standartSaleForFixedPriceStrg));

        assert(
            executionManager.isStrategyWhitelisted(
                address(anyItemFromCollectionForFixedPriceStrg)
            )
        );
        assert(
            executionManager.isStrategyWhitelisted(address(privateSaleStrg))
        );
        assert(
            executionManager.isStrategyWhitelisted(
                address(standartSaleForFixedPriceStrg)
            )
        );
        assert(executionManager.viewCountWhitelistedStrategies() == 3);

        // MOCK NFTs
        nft1 = new MockERC721("Non Fungible Token1", "NFT1");
        nft2 = new MockERC721("Non Fungible Token2", "NFT2");
        nft3 = new MockERC721("Non Fungible Token3", "NFT3");
        usdt = new MockERC20("Tether USD", "USDTC", 6);
        currencyManager.addCurrency(address(usdt));
        vm.stopPrank();
    }

    function mintERC721(
        MockERC721 token,
        address to,
        uint256 amount
    ) public {
        token.mintMany(to, amount);
        // assert(token.ownerOf())
    }

    function toUSDT(uint256 amount) public pure returns(uint256) {
        return amount*1e6;
    }

    function mintErc20TokensTo(
        address to,
        address token,
        uint256 amount
    ) internal {
        MockERC20(token).mint(to, amount);
    }

    function mintTokensTo(
        address to,
        MockERC20 token,
        uint256 amount
    ) internal {
        token.mint(to, amount);
    }

    // function skip(uint256 time) public {
    //     vm.warp(block.timestamp + time);
    // }
}
