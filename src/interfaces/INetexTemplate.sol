pragma solidity 0.8.17;

// TODO: renmae to INetexNFTTemplate
interface INetexTemplate {
    function initialize(
        string memory name,
        string memory symbol,
        address minter,
        address initialOwner,
        bytes calldata data
    ) external;
}