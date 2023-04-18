pragma solidity 0.8.17;

import "forge-std/console.sol";
import {BaseTest} from "./BaseTest.t.sol";
import {OrderTypes} from "../src/libraries/OrderTypes.sol";
import {SigUtils} from "./utils/SigUtils.sol";
import {MockERC721} from "./mocks/MockERC721.sol";
import {MockERC20} from "./mocks/MockERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract NetexExchangeTest is BaseTest {
    SigUtils public sigUtils;
    uint256 public constant MAX_UINT = type(uint256).max;
    mapping(address => uint256) userNonce;

    function setUp() public override {
        skip(1675079661);
        super.setUp();
        sigUtils = new SigUtils(exchange.DOMAIN_SEPARATOR());
    }

    function testMatchAskWithTakerBidUsingETHAndWETH(
        uint256 price,
        uint256 deadline
    ) public {
        /// note Alice lists nft
        /// note Bob takes bid
        vm.assume(price < 200 ether);
        vm.assume(price > 1e5);
        console.logString("price:");
        console.logUint(price);

        vm.assume(deadline > block.timestamp);
        vm.startPrank(alice);
        mintERC721(nft1, alice, 2);

        nft1.setApprovalForAll(address(transferManagerERC721), true);

        uint256 startTime = block.timestamp;
        uint256 tokenId = 1;

        OrderTypes.MakerOrder memory order = createOrderForFixedPrice(
            true,
            alice,
            alicePK,
            address(nft1),
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

        uint256 protocolFee = ((price * standartSaleForFixedPriceStrg.viewProtocolFee()) / 10000);
        uint256 feeRecipientBalanceBefore = weth.balanceOf(protocolFeeRecipient);
        exchange.matchAskWithTakerBidUsingETHAndWETH{value: price}(takerBid, order);
        console.logString("feeRecipientBalanceBefore:");
        console.logUint(feeRecipientBalanceBefore);
        console.logString("after");
        console.logUint(protocolFeeRecipient.balance);
        console.logString("protocolFee");
        console.logUint(protocolFee);

        assert(
            weth.balanceOf(protocolFeeRecipient) == feeRecipientBalanceBefore + protocolFee
        );
    }

    function testMatchAskWithTakerBidWithWETH(uint256 price, uint256 deadline)
        public
    {
        /// note Alice lists nft
        /// note Bob takes bid
        vm.assume(price < 50 ether);
        vm.assume(deadline > block.timestamp);

        mintERC721(nft1, alice, 2);

        _matchAskWithTakerBid(
            alice,
            alicePK,
            bob,
            nft1,
            address(weth),
            1,
            price,
            deadline
        );
    }

    function testMatchAskWithTakerBidWithUSDT(uint256 price, uint256 deadline)
        public
    {
        /// note Alice lists nft
        /// note Bob takes bid
        vm.assume(price >= 100);
        vm.assume(price < toUSDT(100000000));
        vm.assume(deadline > block.timestamp);
        // vm.startPrank(alice);
        mintERC721(nft1, alice, 2);

        _matchAskWithTakerBid(
            alice,
            alicePK,
            bob,
            nft1,
            address(usdt),
            1,
            price,
            deadline
        );
    }

    function testMatchBidWithTakerAsk(uint256 price, uint256 deadline) public {
        /// note: Bob makes an offer for Allisa's nft
        /// note: Alice takes an offer
        vm.assume(price < 50 ether);
        vm.assume(deadline > block.timestamp);
        vm.startPrank(bob);
        mintERC721(nft1, alice, 2);

        weth.deposit{value: price}();
        weth.approve(address(exchange), MAX_UINT);

        uint256 startTime = block.timestamp - (10 days);

        OrderTypes.MakerOrder memory makerOrder = createOrderForFixedPrice(
            false,
            bob,
            bobPK,
            address(nft1),
            address(weth),
            1,
            price,
            startTime,
            deadline
        );

        vm.stopPrank();
        vm.startPrank(alice);

        OrderTypes.TakerOrder memory takerOrder = OrderTypes.TakerOrder({
            isOrderAsk: true,
            taker: alice,
            price: price,
            tokenId: 1,
            minPercentageToAsk: 9000,
            params: ""
        });
        nft1.setApprovalForAll(address(transferManagerERC721), true);

        exchange.matchBidWithTakerAsk(takerOrder, makerOrder);

        assert(nft1.ownerOf(1) == bob);
    }

    function testCancelMultipleMakerOrders(uint256 price) public {
        vm.assume(price < 50 ether);
        vm.stopPrank();
        vm.startPrank(alice);
        mintERC721(nft1, alice, 2);

        nft1.setApprovalForAll(address(transferManagerERC721), true);

        uint256 startTime = block.timestamp - (10 days);
        uint256 deadline = block.timestamp + 15 days;

        uint256[] memory nonces = new uint256[](2);
        nonces[0] = userNonce[alice];
        OrderTypes.MakerOrder memory order1 = createOrderForFixedPrice(
            true,
            alice,
            alicePK,
            address(nft1),
            address(weth),
            1,
            price,
            startTime,
            deadline
        );

        skip(10 seconds);

        nonces[1] = userNonce[alice];
        OrderTypes.MakerOrder memory order2 = createOrderForFixedPrice(
            true,
            alice,
            alicePK,
            address(nft1),
            address(weth),
            2,
            price,
            startTime,
            deadline
        );

        exchange.cancelMultipleMakerOrders(nonces);

        assert(exchange.isUserOrderNonceExecutedOrCancelled(alice, userNonce[alice]-1));

        vm.stopPrank();
        vm.startPrank(bob);

        weth.deposit{value: price}();
        weth.approve(address(exchange), MAX_UINT);

        OrderTypes.TakerOrder memory takerBid = OrderTypes.TakerOrder({
            isOrderAsk: false,
            taker: bob,
            price: price,
            tokenId: 1,
            minPercentageToAsk: 9000,
            params: ""
        });

        vm.expectRevert("Order: Matching order expired");
        exchange.matchAskWithTakerBidUsingETHAndWETH(takerBid, order1);
        vm.expectRevert("Order: Matching order expired");
        exchange.matchAskWithTakerBidUsingETHAndWETH(takerBid, order2);
    }

    function testCancelAllOrdersForSender() public {
        vm.stopPrank();
        vm.startPrank(alice);
        mintERC721(nft1, alice, 2);

        nft1.setApprovalForAll(address(transferManagerERC721), true);

        uint256 startTime = block.timestamp - (10 days);
        uint256 deadline = block.timestamp + 15 days;
        uint256 price = 1 ether;

        OrderTypes.MakerOrder memory order1 = createOrderForFixedPrice(
            true,
            alice,
            alicePK,
            address(nft1),
            address(weth),
            1,
            price,
            startTime,
            deadline
        );

        skip(10 seconds);

        OrderTypes.MakerOrder memory order2 = createOrderForFixedPrice(
            true,
            alice,
            alicePK,
            address(nft1),
            address(weth),
            2,
            price,
            startTime,
            deadline
        );

        exchange.cancelAllOrdersForSender(userNonce[alice]);

        assert(exchange.userMinOrderNonce(alice) == userNonce[alice]);

        vm.stopPrank();
        vm.startPrank(bob);

        weth.deposit{value: price}();
        weth.approve(address(exchange), MAX_UINT);

        OrderTypes.TakerOrder memory takerBid = OrderTypes.TakerOrder({
            isOrderAsk: false,
            taker: bob,
            price: price,
            tokenId: 1,
            minPercentageToAsk: 9000,
            params: ""
        });

        vm.expectRevert("Order: Matching order expired");
        exchange.matchAskWithTakerBidUsingETHAndWETH(takerBid, order1);
        vm.expectRevert("Order: Matching order expired");
        exchange.matchAskWithTakerBidUsingETHAndWETH(takerBid, order2);
    }

    function createOrderForFixedPrice(
        bool isOrderAsk,
        address signer,
        uint256 signerPK,
        address collection,
        address currency,
        uint256 tokenId,
        uint256 price,
        uint256 startTime,
        uint256 deadline
    ) internal returns (OrderTypes.MakerOrder memory) {
        OrderTypes.MakerOrder memory makerOrder = OrderTypes.MakerOrder({
            isOrderAsk: isOrderAsk,
            signer: signer,
            collection: collection,
            price: price,
            tokenId: tokenId,
            amount: 1,
            strategy: address(standartSaleForFixedPriceStrg),
            currency: currency,
            nonce: userNonce[signer]++,
            startTime: startTime,
            endTime: deadline,
            minPercentageToAsk: 9850,
            params: "",
            v: 0,
            r: "",
            s: ""
        });

        makerOrder = signOrder(makerOrder, signerPK);
        return makerOrder;
    }

    function _matchAskWithTakerBid(
        address maker,
        uint256 makerPK,
        address taker,
        MockERC721 nft,
        address currency,
        uint256 tokenId,
        uint256 price,
        uint256 deadline
    ) private {
        vm.startPrank(maker);
        nft.setApprovalForAll(address(transferManagerERC721), true);

        uint256 startTime = block.timestamp;

        OrderTypes.MakerOrder memory order = createOrderForFixedPrice(
            true,
            maker,
            makerPK,
            address(nft),
            currency,
            tokenId,
            price,
            startTime,
            deadline
        );

        vm.stopPrank();
        vm.startPrank(taker);

        if (currency == address(weth)) {
            weth.deposit{value: price}();
        } else {
            mintErc20TokensTo(taker, currency, price);
        }

        IERC20(currency).approve(address(exchange), MAX_UINT);

        OrderTypes.TakerOrder memory takerBid = OrderTypes.TakerOrder({
            isOrderAsk: false,
            taker: taker,
            price: price,
            tokenId: tokenId,
            minPercentageToAsk: 9000,
            params: ""
        });

        uint256 protocolFee = ((price *
            standartSaleForFixedPriceStrg.viewProtocolFee()) / 10000);
        exchange.matchAskWithTakerBid(takerBid, order);
        assert(IERC20(currency).balanceOf(protocolFeeRecipient) >= protocolFee);
        assert(nft.ownerOf(tokenId) == taker);
    }

    function signOrder(
        OrderTypes.MakerOrder memory makerOrder,
        uint256 signerPK
    ) internal view returns (OrderTypes.MakerOrder memory) {
        bytes32 digest = sigUtils.getTypedDataHash(makerOrder);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(signerPK, digest);

        makerOrder.v = v;
        makerOrder.r = r;
        makerOrder.s = s;

        return makerOrder;
    }
}
