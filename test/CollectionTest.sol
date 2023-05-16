pragma solidity 0.8.17;

import {console} from "forge-std/console.sol";

import "./utils/LazyMintSigUtils.sol";
import {NetexERC721Collection} from "../src/netex-collection/NetexERC721Collection.sol";
import {Clones} from "@openzeppelin/contracts/proxy/Clones.sol";
import {LibERC721LazyMint} from "../src/libraries/LibERC721LazyMint.sol";
import {NetexExchangeTest} from "./NetexExchangeTest.t.sol";
import {OrderTypes} from "../src/libraries/OrderTypes.sol";

contract NetexERC721CollectionTest is NetexExchangeTest {
    NetexERC721Collection netexCollection;
    LazyMintSigUtils lazySigUtils;

    uint256 public collectionDeployerPK;
    address public collectionDeployer;

    uint256 public user1PK;
    address public user1;

    uint256 public user2PK;
    address public user2;

    function setUp() public virtual override {
        super.setUp();
        collectionDeployerPK = 0xC011ec11011;
        collectionDeployer = vm.addr(collectionDeployerPK);

        user1PK = 0x1111111;
        user1 = vm.addr(user1PK);

        user2PK = 0x2222222;
        user2 = vm.addr(user2PK);

        vm.startPrank(collectionDeployer);

        string memory name = "Netex Collection";
        string memory symbol = "NETEX";
        address initialOwner = collectionDeployer;

        netexCollection = new NetexERC721Collection(
            name,
            symbol,
            initialOwner,
            "0x"
        );
        lazySigUtils = new LazyMintSigUtils(netexCollection.DOMAIN_SEPARATOR());
        vm.stopPrank();
    }

    function testListAndBuy(uint256 price, uint256 deadline) public {
        /// note Alice lists nft
        /// note Bob takes bid
        vm.assume(price < 200 ether);
        vm.assume(price > 1e5);
        console.logString("price:");
        console.logUint(price);

        vm.assume(deadline > block.timestamp);
        vm.startPrank(alice);

        netexCollection.setApprovalForAll(address(transferManagerERC721), true);

        uint256 startTime = block.timestamp;
        uint256 shiftedMinterValue = uint256(uint160(alice)) << 96;
        uint256 tokenId = shiftedMinterValue | 2;

        OrderTypes.MakerOrder memory order = createOrderForFixedPrice(
            true,
            alice,
            alicePK,
            address(netexCollection),
            address(weth),
            tokenId,
            price,
            startTime,
            deadline
        );

        vm.stopPrank();
        vm.startPrank(bob);

        OrderTypes.TakerOrder memory takerBid = OrderTypes.TakerOrder({
            isOrderAsk: false,
            taker: bob,
            price: price,
            tokenId: tokenId,
            minPercentageToAsk: 9000,
            params: ""
        });

        uint256 protocolFee = ((price *
            standartSaleForFixedPriceStrg.viewProtocolFee()) / 10000);
        uint256 feeRecipientBalanceBefore = weth.balanceOf(
            protocolFeeRecipient
        );
        LibERC721LazyMint.Mint721Data memory mintData = LibERC721LazyMint
            .Mint721Data({
                tokenId: tokenId,
                tokenURI: "ipfs://ipfs",
                creator: alice,
                royalty: 1000,
                signature: ""
            });
        mintData = signData(mintData, alicePK);

        weth.deposit{value: price}();
        weth.approve(address(exchange), MAX_UINT);

        bytes memory data = abi.encode(mintData);

        exchange.matchAskWithTakerBid(
            takerBid,
            order,
            data
        );
        console.logString("feeRecipientBalanceBefore:");
        console.logUint(feeRecipientBalanceBefore);
        console.logString("after");
        console.logUint(protocolFeeRecipient.balance);
        console.logString("protocolFee");
        console.logUint(protocolFee);

        assert(
            weth.balanceOf(protocolFeeRecipient) ==
                feeRecipientBalanceBefore + protocolFee
        );
    }

    function testTransferFromOrMint() external {
        vm.startPrank(user1);

        uint256 shiftedMinterValue = uint256(uint160(user1)) << 96;

        uint256 tokenId = shiftedMinterValue | 1;
        LibERC721LazyMint.Mint721Data memory mintData = LibERC721LazyMint
            .Mint721Data({
                tokenId: tokenId,
                tokenURI: "ipfs://ipfs",
                creator: user1,
                royalty: 1000,
                signature: ""
            });
        mintData = signData(mintData, user1PK);
        address from = user1;
        address to = user1;

        // mintData.royalty = 4000;

        netexCollection.transferFromOrMint(mintData, from, to);
        vm.stopPrank();
    }

    function signData(
        LibERC721LazyMint.Mint721Data memory mintData,
        uint256 signerPK
    ) internal view returns (LibERC721LazyMint.Mint721Data memory) {
        bytes32 digest = lazySigUtils.getTypedDataHash(mintData);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(signerPK, digest);

        // console.log("r");
        // console.logBytes32(r);

        bytes memory signature = abi.encodePacked(r, s, v);

        mintData.signature = signature;

        return mintData;
    }
}
