//SPDX-License-Identifier: Unlicense

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import './SafeMath.sol';
import './Ownable.sol';
import './IERC20.sol';

contract GreenPay is Ownable {
	using SafeMath for uint256;

	address payable public feeAccount;

	struct BuyInfo {
		address buyerAddress; 
		address sellerAddress;
		uint256 value;
		address currency;
	}

	mapping(address => mapping(uint256 => BuyInfo)) public payment;
	mapping(address => uint256) public balances;

	uint256 public balanceFee;
	uint256 public feePercent;

	constructor(address payable _feeAccount, uint256 _feePercent) public {
		feeAccount = _feeAccount;
		feePercent = _feePercent;
	}

	fallback() external {
		revert();
	}

	function getBuyerAddressPayment(address _sellerAddress, uint256 _orderId) public view returns(address) {
		return payment[_sellerAddress][_orderId].buyerAddress;
	}

	function getSellerAddressPayment(address _sellerAddress, uint256 _orderId) public view returns(address) {
		return payment[_sellerAddress][_orderId].sellerAddress;
	}

	function getValuePayment(address _sellerAddress, uint256 _orderId) public view returns(uint256) {
		return payment[_sellerAddress][_orderId].value;
	}
    
	function getCurrencyPayment(address _sellerAddress, uint256 _orderId) public view returns(address) {
		return payment[_sellerAddress][_orderId].currency;
	}

	function setFeeAccount(address payable _feeAccount) onlyOwner public {
		feeAccount = _feeAccount;  
	}

	function setFeePercent(uint256 _feePercent) onlyOwner public {
		feePercent = _feePercent;  
	}

	function payToken(address _tokenAddress, address _sellerAddress, uint256 _orderId,  uint256 _value) public returns(bool) {
		require(_tokenAddress != address(0));
		require(_sellerAddress != address(0)); 
		require(_value > 0);
		IERC20 token = IERC20(_tokenAddress);
		require(token.allowance(msg.sender, address(this)) >= _value);
		token.transferFrom(msg.sender, feeAccount, _value.mul(feePercent).div(100));
		token.transferFrom(msg.sender, _sellerAddress, _value.sub(_value.mul(feePercent).div(100)));
		payment[_sellerAddress][_orderId] = BuyInfo(msg.sender, _sellerAddress, _value, _tokenAddress);
		return true;
	}

	function payCoin(address payable _sellerAddress, uint256 _orderId, uint256 _value) public returns(bool) {
		require(_sellerAddress != address(0)); 
		require(_value > 0);
		require(balances[msg.sender] >= _value);
		uint256 fee = _value.mul(feePercent).div(100);
		balances[msg.sender] = balances[msg.sender].sub(_value);
		_sellerAddress.transfer(_value.sub(fee));
		balanceFee = balanceFee.add(fee);
		payment[_sellerAddress][_orderId] = BuyInfo(msg.sender, _sellerAddress, _value, 0x0000000000000000000000000000000000000000);    
		return true;
	}

	function transferFee() onlyOwner public {
		uint256 valfee = balanceFee.div(2);
		feeAccount.transfer(valfee);
		balanceFee = balanceFee.sub(valfee);
		feeAccount.transfer(balanceFee);
		balanceFee = 0;
	}

	function balanceOfToken(address _tokenAddress, address _Address) public view returns(uint256) {
		IERC20 token = IERC20(_tokenAddress);
		return token.balanceOf(_Address);
	}

	function balanceOfCoinFee() public view returns(uint256) {
		return balanceFee;
	}

	function refund() public{
		require(balances[msg.sender] > 0);
		uint256 value = balances[msg.sender];
		balances[msg.sender] = 0;
		msg.sender.transfer(value);
	}

	function getBalanceCoin() public view returns(uint256){
		return balances[msg.sender];    
	}
}