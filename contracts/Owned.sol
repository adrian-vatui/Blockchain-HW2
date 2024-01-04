// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.2 <0.9.0;

abstract contract Owned {
    address payable internal owner;
    event fallbackCall(string);
    event receivedFunds(address, uint);

    constructor() {
        owner = payable(msg.sender);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Caller is not owner");
        _;
    }

    receive () payable external {
        emit receivedFunds(msg.sender, msg.value);
    }

    fallback () external {
        emit fallbackCall("Falback Called!");
    }
}