// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {OrderTypes} from "../libraries/OrderTypes.sol";

interface INetexExchange {
    // function matchAskWithTakerBidUsingETH(
    //     OrderTypes.TakerOrder calldata takerBid,
    //     OrderTypes.MakerOrder calldata makerAsk
    // ) external payable;

    function matchAskWithTakerBidUsingETHAndWETH(
        OrderTypes.TakerOrder calldata takerBid,
        OrderTypes.MakerOrder calldata makerAsk,
        bytes calldata data
    ) external payable;

    function matchAskWithTakerBid(
        OrderTypes.TakerOrder calldata takerBid,
        OrderTypes.MakerOrder calldata makerAsk,
        bytes calldata data
    ) external;

    function matchBidWithTakerAsk(
        OrderTypes.TakerOrder calldata takerAsk,
        OrderTypes.MakerOrder calldata makerBid,
        bytes calldata data
    ) external;
}
