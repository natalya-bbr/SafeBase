// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract RegistryV1 is Initializable, UUPSUpgradeable, OwnableUpgradeable {
    struct EscrowMetadata {
        address buyer;
        address seller;
        uint256 amount;
        uint256 createdAt;
        uint8 state;
    }

    mapping(address => uint256[]) public partyEscrows;
    mapping(uint256 => EscrowMetadata) public escrowMetadata;
    uint256[] public allEscrows;

    address public escrowContract;

    event EscrowIndexed(uint256 indexed escrowId, address indexed buyer, address indexed seller);
    event EscrowUpdated(uint256 indexed escrowId, uint8 state);

    error InvalidEscrowContract();
    error Unauthorized();

    function initialize(address _owner) public initializer {
        __Ownable_init(_owner);
    }

    function setEscrowContract(address _escrowContract) external onlyOwner {
        if (_escrowContract == address(0)) revert InvalidEscrowContract();
        escrowContract = _escrowContract;
    }

    function indexEscrow(
        uint256 _escrowId,
        address _buyer,
        address _seller,
        uint256 _amount,
        uint256 _createdAt
    ) external {
        if (msg.sender != escrowContract) revert Unauthorized();

        escrowMetadata[_escrowId] = EscrowMetadata({
            buyer: _buyer,
            seller: _seller,
            amount: _amount,
            createdAt: _createdAt,
            state: 0
        });

        partyEscrows[_buyer].push(_escrowId);
        partyEscrows[_seller].push(_escrowId);
        allEscrows.push(_escrowId);

        emit EscrowIndexed(_escrowId, _buyer, _seller);
    }

    function updateEscrowState(uint256 _escrowId, uint8 _state) external {
        if (msg.sender != escrowContract) revert Unauthorized();
        escrowMetadata[_escrowId].state = _state;
        emit EscrowUpdated(_escrowId, _state);
    }

    function getPartyEscrows(address _party) external view returns (uint256[] memory) {
        return partyEscrows[_party];
    }

    function getPartyEscrowCount(address _party) external view returns (uint256) {
        return partyEscrows[_party].length;
    }

    function getEscrowMetadata(uint256 _escrowId) external view returns (EscrowMetadata memory) {
        return escrowMetadata[_escrowId];
    }

    function getAllEscrows() external view returns (uint256[] memory) {
        return allEscrows;
    }

    function getTotalEscrowCount() external view returns (uint256) {
        return allEscrows.length;
    }

    function getEscrowsPaginated(uint256 _offset, uint256 _limit) external view returns (uint256[] memory) {
        uint256 total = allEscrows.length;
        if (_offset >= total) {
            return new uint256[](0);
        }

        uint256 end = _offset + _limit;
        if (end > total) {
            end = total;
        }

        uint256 length = end - _offset;
        uint256[] memory result = new uint256[](length);

        for (uint256 i = 0; i < length; i++) {
            result[i] = allEscrows[_offset + i];
        }

        return result;
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    uint256[50] private __gap;
}
