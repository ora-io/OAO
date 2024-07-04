// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./transparent/TransparentUpgradeableProxy.sol";
import "../AIOracle.sol";
import "../interfaces/IOpml.sol";
import "hardhat/console.sol";

contract ProxyFactory {

    function _doesAddressStartWith(
        address _address,
        uint160 _prefix
    ) private pure returns (bool) {
        bool condition1 = uint160(_address) / (2 ** (4 * 37)) == _prefix;
        bool condition2 = uint160(_address) & 0xFFF == _prefix;
        return condition1 && condition2;
    }

    function getCreate2Address(address impl, uint256 _salt) public view returns (address) {
        address owner = msg.sender;
        bytes memory data = "";
        bytes32 salt = bytes32(_salt);
        bytes32 bytecodeHash = keccak256(abi.encodePacked(
            type(TransparentUpgradeableProxy).creationCode, abi.encode(impl, owner, data)
        ));
        address predictAddress = address(
            uint160(
                uint(
                    keccak256(
                        abi.encodePacked(
                            bytes1(0xFF),
                            address(this),
                            salt,
                            bytecodeHash
                        )
                    )
                )
            )
        );

        return predictAddress;
    }

    function deploy(address impl, uint _salt) public {
        address owner = msg.sender;
        bytes memory data = "";

        TransparentUpgradeableProxy proxy = new TransparentUpgradeableProxy{
            salt: bytes32(_salt)
        }(impl, owner, data);
        console.log("proxy: ");
        console.log(address(proxy));
    }
}
