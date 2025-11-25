// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract AccessController is Initializable, UUPSUpgradeable, OwnableUpgradeable {
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant MEDIATOR_ROLE = keccak256("MEDIATOR_ROLE");
    bytes32 public constant AUTOMATOR_ROLE = keccak256("AUTOMATOR_ROLE");

    mapping(bytes32 => mapping(address => bool)) public hasRole;
    mapping(bytes32 => uint256) public roleCount;

    event RoleGranted(bytes32 indexed role, address indexed account);
    event RoleRevoked(bytes32 indexed role, address indexed account);

    error InvalidRole();
    error InvalidAddress();
    error AlreadyHasRole();
    error DoesNotHaveRole();

    function initialize(address _owner) public initializer {
        __Ownable_init(_owner);
    }

    function grantRole(bytes32 _role, address _account) external onlyOwner {
        if (_account == address(0)) revert InvalidAddress();
        if (hasRole[_role][_account]) revert AlreadyHasRole();

        hasRole[_role][_account] = true;
        roleCount[_role]++;

        emit RoleGranted(_role, _account);
    }

    function revokeRole(bytes32 _role, address _account) external onlyOwner {
        if (!hasRole[_role][_account]) revert DoesNotHaveRole();

        hasRole[_role][_account] = false;
        roleCount[_role]--;

        emit RoleRevoked(_role, _account);
    }

    function checkRole(bytes32 _role, address _account) external view returns (bool) {
        return hasRole[_role][_account];
    }

    function getRoleCount(bytes32 _role) external view returns (uint256) {
        return roleCount[_role];
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    uint256[50] private __gap;
}
