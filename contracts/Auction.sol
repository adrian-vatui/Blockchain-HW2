// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./SampleToken.sol";
import "./ProductIdentification.sol";

contract Auction {
    
    address payable internal auction_owner;
    uint256 public auction_start;
    uint256 public auction_end;
    uint256 public highestBid;
    address public highestBidder;


    enum auction_state{
        CANCELLED,STARTED
    }

    struct  car{
        string  Brand;
        string  Rnumber;
    }
    
    car public Mycar;
    address[] bidders;

    mapping(address => uint) public bids;

    auction_state public STATE;


    modifier an_ongoing_auction() {
        require(block.timestamp <= auction_end && STATE == auction_state.STARTED);
        _;
    }
    
    modifier only_owner() {
        require(msg.sender==auction_owner);
        _;
    }
    
    function bid(uint bidTokens) public virtual returns (bool) {}
    function withdraw() public virtual returns (bool) {}
    function cancel_auction() external virtual returns (bool) {}
    
    event BidEvent(address indexed highestBidder, uint256 highestBid);
    event WithdrawalEvent(address withdrawer, uint256 amount);
    event CanceledEvent(string message, uint256 time);  
    
}

contract MyAuction is Auction {
    SampleToken private tokenContract;
    ProductIdentification private productIdentification;
    
    constructor (ProductIdentification _productIdentification, uint _biddingTime, address payable _owner, string memory _brand, string memory _Rnumber) {
        require(_productIdentification.isProductRegistered(_brand), "Brand is not a registered product!");
        
        productIdentification = _productIdentification;
        tokenContract = productIdentification.getSampleToken();

        auction_owner = _owner;
        auction_start = block.timestamp;
        auction_end = auction_start + _biddingTime*1 hours;
        STATE = auction_state.STARTED;
        Mycar.Brand = _brand;
        Mycar.Rnumber = _Rnumber;
    } 
    
    function get_owner() public view returns(address) {
        return auction_owner;
    }
    
    fallback () external payable {
        
    }
    
    receive () external payable {
        
    }
    
    function bid(uint bidTokens) public an_ongoing_auction override returns (bool) {
        require(bidTokens > highestBid, "You can't bid, Make a higher Bid!");
        require(bids[msg.sender] == 0, "Already bidded, you can bid only once!");
        require(tokenContract.transferFrom(msg.sender, address(this), bidTokens));

        highestBidder = msg.sender;
        highestBid = bidTokens;
        bidders.push(msg.sender);
        bids[msg.sender] = highestBid;

        emit BidEvent(highestBidder,  highestBid);

        return true;
    } 
    
    function cancel_auction() external only_owner an_ongoing_auction override returns (bool) {
        STATE = auction_state.CANCELLED;
        emit CanceledEvent("Auction Cancelled", block.timestamp);
        return true;
    }
    
    function withdraw() public override returns (bool) {
        require(block.timestamp > auction_end || STATE == auction_state.CANCELLED, "You can't withdraw, the auction is still open");
        require(block.timestamp > auction_end && STATE != auction_state.CANCELLED && msg.sender != highestBidder, "Winner can't withdraw their funds!");
        
        uint amount;
        amount = bids[msg.sender];
        bids[msg.sender] = 0;
        tokenContract.transfer(msg.sender, amount);

        emit WithdrawalEvent(msg.sender, amount);
        return true;
    }

    function withdraw_winnings() external only_owner returns (bool) {
        require(block.timestamp > auction_end && STATE != auction_state.CANCELLED, "You can't withdraw winnings from unsuccessful auction!");

        bids[highestBidder] = 0;
        tokenContract.transfer(auction_owner, highestBid);

        return true;
    }
    
    function destruct_auction() external only_owner returns (bool) {
        require(block.timestamp > auction_end || STATE == auction_state.CANCELLED, "You can't destruct the contract,The auction is still open");

        if (STATE != auction_state.CANCELLED) {
            bids[highestBidder] = 0;
            tokenContract.transfer(auction_owner, highestBid);
        }

        address bidder;
        uint amount;
        for (uint i = 0; i < bidders.length; i++) {
            bidder = bidders[i];
            amount = bids[bidder];
            bids[bidder] = 0;
            tokenContract.transfer(bidder, amount);
        }

        selfdestruct(auction_owner);
        return true;
    }
}