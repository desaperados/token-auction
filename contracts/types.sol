import 'erc20/erc20.sol';

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
        uint duration;
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

