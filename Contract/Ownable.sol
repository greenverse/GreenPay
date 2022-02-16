// SPDX-License-Identifier: Unlicense

pragma solidity ^0.6.12;

contract Ownable {
    address internal owner;

    event LogOnOwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        require(_newOwner != address(0), "Ownable: new owner is the zero address");
        emit LogOnOwnershipTransferred(owner, _newOwner);
        owner = _newOwner;
    }
}
