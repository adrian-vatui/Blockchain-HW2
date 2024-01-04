// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract SampleToken {
    
    string public name = "Sample Token";
    string public symbol = "TOK";

    uint256 private _totalSupply;
    
    event Transfer(address indexed _from,
                   address indexed _to,
                   uint256 _value);

    event Approval(address indexed _owner,
                   address indexed _spender,
                   uint256 _value);

    mapping (address => uint256) private _balanceOf;
    mapping (address => mapping(address => uint256)) private _allowance;

    constructor (uint256 _initialSupply) {
        _balanceOf[msg.sender] = _initialSupply;
        _totalSupply = _initialSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(_balanceOf[msg.sender] >= _value);

        _balanceOf[msg.sender] -= _value;
        _balanceOf[_to] += _value;

        emit Transfer(msg.sender, _to, _value);

        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        _allowance[msg.sender][_spender] = _value;

        emit Approval(msg.sender, _spender, _value);

        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= _balanceOf[_from]);
        require(_value <= _allowance[_from][msg.sender]);

        _balanceOf[_from] -= _value;
        _balanceOf[_to] += _value;
        _allowance[_from][msg.sender] -= _value;

        emit Transfer(_from, _to, _value);

        return true;
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address _owner) public view returns (uint256 balance) {
        return _balanceOf[_owner];
    }

    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return _allowance[_owner][_spender];
    }
}

contract SampleTokenSale {
    
    SampleToken public tokenContract;
    uint256 public tokenPrice;
    address owner;

    uint256 public tokensSold;

    event Sell(address indexed _buyer, uint256 indexed _amount);

    constructor(SampleToken _tokenContract, uint256 _tokenPrice) {
        owner = msg.sender;
        tokenContract = _tokenContract;
        tokenPrice = _tokenPrice;
    }

    function buyTokens(uint256 _numberOfTokens) public payable {
        uint256 amountToPay = _numberOfTokens * tokenPrice;
        require(msg.value >= amountToPay);
        require(tokenContract.allowance(owner, address(this)) >= _numberOfTokens);
        require(tokenContract.transferFrom(owner, msg.sender, _numberOfTokens));

        tokensSold += _numberOfTokens;

        payable(msg.sender).transfer(msg.value - amountToPay);

        emit Sell(msg.sender, _numberOfTokens);
    }

    function endSale() public {
        require(msg.sender == owner);
        require(tokenContract.transfer(owner, tokenContract.balanceOf(address(this))));
        payable(msg.sender).transfer(address(this).balance);
    }

    function setTokenPrice(uint256 _price) public {
        require(msg.sender == owner);

        tokenPrice = _price;
    }
}