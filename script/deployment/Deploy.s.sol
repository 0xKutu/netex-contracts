pragma solidity ^0.8.17;

import "forge-std/Script.sol";
import {CurrencyManager} from "../../src/CurrencyManager.sol";
import {ExecutionManager} from "../../src/ExecutionManager.sol";
import {RoyaltyFeeRegistry} from "../../src/fee/RoyaltyFeeRegistry.sol";
import {RoyaltyFeeManagerV1B} from "../../src/RoyaltyFeeManagerV1B.sol";
import {TransferSelectorNFT} from "../../src/TransferSelectorNFT.sol";
import {NetexExchange} from "../../src/NetexExchange.sol";
import {WETH} from "../../src/tokens/WETH.sol";
import {TransferManagerERC721} from "../../src/utils/TransferManagerERC721.sol";
import {TransferManagerERC1155} from "../../src/utils/TransferManagerERC1155.sol";
import {FeeSharingSetter} from "../../src/fee/FeeSharingSetter.sol";
import {StrategyAnyItemFromCollectionForFixedPriceV1B} from "../../src/strategies/StrategyAnyItemFromCollectionForFixedPriceV1B.sol";
import {StrategyPrivateSale} from "../../src/strategies/StrategyPrivateSale.sol";
import {StrategyStandardSaleForFixedPriceV1B} from "../../src/strategies/StrategyStandardSaleForFixedPriceV1B.sol";
import {NetexStack} from "./NetexStack.sol";

contract Deploy is Script, NetexStack {
    uint256 public constant ROYALTY_FEE_LIMIT = 9500;
    address public protocolFeeRecipient =
        0xf64AbA0a3E3C77B0b01c6b642623fbF5dD11c214;

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

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        // NFT nft = new NFT("NFT_tutorial", "TUT", "baseUri");
        if (WETH9_ADDRESS != address(0)) {
            weth = WETH(payable(WETH9_ADDRESS));
        } else {
            weth = new WETH();
            writeContractAddressToFile("WETH9", address(weth));
        }

        if (CURRENCY_MANAGER_ADDRESS != address(0)) {
            currencyManager = CurrencyManager(CURRENCY_MANAGER_ADDRESS);
        } else {
            currencyManager = new CurrencyManager();
            writeContractAddressToFile(
                "CURRENCY_MANAGER",
                address(currencyManager)
            );
        }

        if (!currencyManager.isCurrencyWhitelisted(address(weth))) {
            currencyManager.addCurrency(address(weth));
        }

        if (EXECUTION_MANAGER_ADDRESS != address(0)) {
            executionManager = ExecutionManager(EXECUTION_MANAGER_ADDRESS);
        } else {
            executionManager = new ExecutionManager();
            writeContractAddressToFile(
                "EXECUTION_MANAGER",
                address(executionManager)
            );
        }

        if (ROYALITY_FEE_REGISTRY_ADDRESS != address(0)) {
            royaltyFeeRegistry = RoyaltyFeeRegistry(
                ROYALITY_FEE_REGISTRY_ADDRESS
            );
        } else {
            royaltyFeeRegistry = new RoyaltyFeeRegistry(ROYALTY_FEE_LIMIT);
            writeContractAddressToFile(
                "ROYALITY_FEE_REGISTRY",
                address(royaltyFeeRegistry)
            );
        }

        if (ROYALITY_FEE_MANAGER_ADDRESS != address(0)) {
            royaltyFeeManager = RoyaltyFeeManagerV1B(
                ROYALITY_FEE_MANAGER_ADDRESS
            );
        } else {
            royaltyFeeManager = new RoyaltyFeeManagerV1B(
                address(royaltyFeeRegistry)
            );
            writeContractAddressToFile(
                "ROYALITY_FEE_MANAGER",
                address(royaltyFeeManager)
            );
        }

        if (NETEX_EXCHANGE_ADDRESS != address(0)) {
            exchange = NetexExchange(NETEX_EXCHANGE_ADDRESS);
        } else {
            exchange = new NetexExchange(
                address(currencyManager),
                address(executionManager),
                address(royaltyFeeManager),
                address(weth),
                address(protocolFeeRecipient)
            );
            writeContractAddressToFile("NETEX_EXCHANGE", address(exchange));
        }

        // MANAGERS

        if (TRANSFER_MANAGER_ERC721_ADDRESS != address(0)) {
            transferManagerERC721 = TransferManagerERC721(
                TRANSFER_MANAGER_ERC721_ADDRESS
            );
        } else {
            transferManagerERC721 = new TransferManagerERC721(
                address(exchange)
            );
            writeContractAddressToFile(
                "TRANSFER_MANAGER_ERC721",
                address(transferManagerERC721)
            );
        }

        if (TRANSFER_MANAGER_ERC1155_ADDRESS != address(0)) {
            transferManagerERC1155 = TransferManagerERC1155(
                TRANSFER_MANAGER_ERC1155_ADDRESS
            );
        } else {
            transferManagerERC1155 = new TransferManagerERC1155(
                address(exchange)
            );
            writeContractAddressToFile(
                "TRANSFER_MANAGER_ERC1155",
                address(transferManagerERC1155)
            );
        }

        if (TRANSFER_SELECTOR_NFT_ADDRESS != address(0)) {
            transferSelectorNFT = TransferSelectorNFT(
                TRANSFER_SELECTOR_NFT_ADDRESS
            );
        } else {
            transferSelectorNFT = new TransferSelectorNFT(
                address(transferManagerERC721),
                address(transferManagerERC1155)
            );
            writeContractAddressToFile(
                "TRANSFER_SELECTOR_NFT",
                address(transferSelectorNFT)
            );
        }

        if (address(exchange.transferSelectorNFT()) == address(0)) {
            exchange.updateTransferSelectorNFT(address(transferSelectorNFT));
        }

        // STRATEGIES
        if (STRATEGY_ANY_ITEM_FOR_FIXED_PRICE_ADDRESS != address(0)) {
            anyItemFromCollectionForFixedPriceStrg = StrategyAnyItemFromCollectionForFixedPriceV1B(
                STRATEGY_ANY_ITEM_FOR_FIXED_PRICE_ADDRESS
            );
        } else {
            anyItemFromCollectionForFixedPriceStrg = new StrategyAnyItemFromCollectionForFixedPriceV1B();
            writeContractAddressToFile(
                "STRATEGY_ANY_ITEM_FOR_FIXED_PRICE",
                address(anyItemFromCollectionForFixedPriceStrg)
            );
        }

        if (STRATEGY_PRIVATE_SALE_ADDRESS == address(0)) {
            privateSaleStrg = new StrategyPrivateSale(0);
            writeContractAddressToFile(
                "STRATEGY_PRIVATE_SALE",
                address(privateSaleStrg)
            );
        } else {
            privateSaleStrg = StrategyPrivateSale(
                STRATEGY_PRIVATE_SALE_ADDRESS
            );
        }

        if (STRATEGY_STANDART_SALE_FOR_FIXED_PRICE_ADDRESS == address(0)) {
            standartSaleForFixedPriceStrg = new StrategyStandardSaleForFixedPriceV1B();
            writeContractAddressToFile(
                "STRATEGY_STANDART_SALE_FOR_FIXED_PRICE",
                address(standartSaleForFixedPriceStrg)
            );
        } else {
            standartSaleForFixedPriceStrg = StrategyStandardSaleForFixedPriceV1B(
                STRATEGY_STANDART_SALE_FOR_FIXED_PRICE_ADDRESS
            );
        }

        
        if(!executionManager.isStrategyWhitelisted(address(standartSaleForFixedPriceStrg))) {
            executionManager.addStrategy(address(standartSaleForFixedPriceStrg));
        }

        if(!executionManager.isStrategyWhitelisted(address(anyItemFromCollectionForFixedPriceStrg))) {
            executionManager.addStrategy(
                address(anyItemFromCollectionForFixedPriceStrg)
            );
        }

        if(!executionManager.isStrategyWhitelisted(address(privateSaleStrg))) {
            executionManager.addStrategy(address(privateSaleStrg));
        }

        vm.stopBroadcast();
    }

    function writeContractAddressToFile(
        string memory contractName,
        address contractAddress
    ) private {
        vm.writeLine(
            string(".env"),
            string(
                abi.encodePacked(
                    contractName,
                    "=",
                    vm.toString(contractAddress)
                )
            )
        );
    }
}
