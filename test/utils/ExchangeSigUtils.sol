// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;
import {OrderTypes} from "../../src/libraries/OrderTypes.sol";

contract ExchangeSigUtils {
    using OrderTypes for OrderTypes.MakerOrder;

    // keccak256("MakerOrder(bool isOrderAsk,address signer,address collection,uint256 price,uint256 tokenId,uint256 amount,address strategy,address currency,uint256 nonce,uint256 startTime,uint256 endTime,uint256 minPercentageToAsk,bytes params)")
    bytes32 internal constant MAKER_ORDER_HASH =
        0x40261ade532fa1d2c7293df30aaadb9b3c616fae525a0b56d3d411c841a85028;
    bytes32 internal immutable DOMAIN_SEPARATOR;

    constructor(bytes32 _DOMAIN_SEPARATOR) {
        DOMAIN_SEPARATOR = _DOMAIN_SEPARATOR;
    }

    // computes the hash of a maker
    function hash(OrderTypes.MakerOrder memory makerOrder)
        internal
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encode(
                    MAKER_ORDER_HASH,
                    makerOrder.isOrderAsk,
                    makerOrder.signer,
                    makerOrder.collection,
                    makerOrder.price,
                    makerOrder.tokenId,
                    makerOrder.amount,
                    makerOrder.strategy,
                    makerOrder.currency,
                    makerOrder.nonce,
                    makerOrder.startTime,
                    makerOrder.endTime,
                    makerOrder.minPercentageToAsk,
                    keccak256(makerOrder.params)
                )
            );
    }

    // computes the hash of the fully encoded EIP-712 message for the domain, which can be used to recover the signer
    function getTypedDataHash(OrderTypes.MakerOrder memory makerAsk)
        public
        view
        returns (bytes32)
    {
        return
            keccak256(
                abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR, makerAsk.hash())
            );
    }
}
