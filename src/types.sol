pragma solidity ^0.4.0;

import 'ds-token/base.sol';

contract AuctionType {
    struct Auction {
        address creator;
        address[] beneficiaries;
        uint[] payouts;
        address refund;
        ERC20 selling;
        ERC20 buying;
        uint start_bid;
        uint min_increase;
        uint min_decrease;
        uint sell_amount;
        uint collected;
        uint collection_limit;
        uint ttl;
        uint expiration;
        bool reversed;
        uint unsold;
    }
    struct Auctionlet {
        uint     auction_id;
        address  last_bidder;
        uint     last_bid_time;
        uint     buy_amount;
        uint     sell_amount;
        bool     unclaimed;
        bool     base;
    }
}

contract AuctionFrontendType {
    function bid(uint auctionlet_id, uint bid_how_much);
    function claim(uint auctionlet_id);
}

contract SplittingAuctionFrontendType {
    function bid(uint auctionlet_id, uint bid_how_much, uint quantity)
        returns (uint new_id, uint split_id);
    function claim(uint auctionlet_id);
}
