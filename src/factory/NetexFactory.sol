pragma solidity 0.8.17;

import {Clones} from "@openzeppelin/contracts/proxy/Clones.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {INetexTemplate} from "../interfaces/INetexTemplate.sol";

/**
 * @author 0xkutu.eth
 * @dev
 * - NFT smart contract factory
 * -
 */

contract NetexFactory is Ownable {
    error NonexistentTemplate();
    error ZeroAddressTemplate();
    error TemplateAlreadyExists();

    event ContractCreated(
        address indexed owner,
        address indexed addr,
        address contractTemplate
    );

    address public minter;
    
    mapping(address => bool) public templates;

    constructor(address _minter) {
        minter = _minter;
    }

        /**
     * @notice Function to add an contract template to create through factory.
     * @dev Send should be owner.
     * @param _template Contract template to create an contract.
     */
    function addTemplate(address _template) external onlyOwner {
        if(_template == address(0)) revert ZeroAddressTemplate();
        if(templates[_template]) revert TemplateAlreadyExists();

        templates[_template] = true;
    }

    /**
     * @notice Creates a new contract cloned from template.
     * @param _template address of the contract template for creating.
     * @return newContract Contract address.
     */
    function createClone(
        address _template,
        string memory _name,
        string memory _symbol,
        bytes calldata _data
    ) external payable returns (address newContract) {
        newContract = _deployContract(_template, _name, _symbol, _data, 0x0);
        return newContract;
    }

    /**
     * @notice Creates a new contract cloned from template.
     * @param _template Id of the template to create.
     * @param _data Id of the template to create.
     * @return newContract Contract address.
     */
    function createCloneDeterministic(
        address _template,
        string memory _name,
        string memory _symbol,
        bytes calldata _data,
        bytes32 _salt
    ) external payable returns (address newContract) {
        newContract = _deployContract(_template, _name, _symbol, _data, _salt);
        return newContract;
    }

    function _deployContract(
        address _template,
        string memory _name,
        string memory _symbol,
        bytes calldata _data,
        bytes32 _salt
    ) private returns (address clone) {
        if (!templates[_template]) revert NonexistentTemplate();
        if(_salt == bytes32(0)) {
            clone = Clones.clone(_template);
        } else {
            // Derive a pseudo-random salt, so clone addresses don't collide
            // across chains.
            bytes32 cloneSalt = keccak256(
                abi.encodePacked(_salt, blockhash(block.number))
            );
            clone = Clones.cloneDeterministic(_template, cloneSalt);
        }
        INetexTemplate(clone).initialize(_name, _symbol, minter, msg.sender, _data);
    }
}
