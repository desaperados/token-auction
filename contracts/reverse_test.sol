import 'dapple/test.sol';
import 'erc20/base.sol';
import 'auction_manager.sol';

contract Manager is AuctionManager {
    uint public debug_timestamp;

    function getTime() public constant returns (uint) {
        return debug_timestamp;
    }
    function setTime(uint timestamp) {
        debug_timestamp = timestamp;
    }
    function getCollectMax(uint auction_id) returns (uint) {
        return _auctions[auction_id].COLLECT_MAX;
    }
    function isReversed(uint auction_id) returns (bool) {
        return _auctions[auction_id].reversed;
    }
}

contract AuctionTester is Tester {
    Manager manager;
    function bindManager(Manager _manager) {
        _target(_manager);
        manager = Manager(_t);
    }
    function doApprove(address spender, uint value, ERC20 token) {
        token.approve(spender, value);
    }
    function doBid(uint auctionlet_id, uint bid_how_much)
    {
        return manager.bid(auctionlet_id, bid_how_much);
    }
    function doClaim(uint id) {
        return manager.claim(id);
    }
}

contract ReverseTest is Test {
    Manager manager;
    AuctionTester seller;
    AuctionTester bidder1;
    AuctionTester bidder2;

    ERC20 t1;
    ERC20 t2;

    uint constant T1 = 10 ** 12;
    uint constant T2 = 10 ** 10;

    function setUp() {
        manager = new Manager();
        manager.setTime(block.timestamp);

        var million = 10 ** 6;

        t1 = new ERC20Base(million * T1);
        t2 = new ERC20Base(million * T2);

        seller = new AuctionTester();
        seller.bindManager(manager);

        t1.transfer(seller, 200 * T1);
        seller.doApprove(manager, 200 * T1, t1);

        bidder1 = new AuctionTester();
        bidder1.bindManager(manager);

        t2.transfer(bidder1, 1000 * T2);
        bidder1.doApprove(manager, 1000 * T2, t2);

        bidder2 = new AuctionTester();
        bidder2.bindManager(manager);

        t2.transfer(bidder2, 1000 * T2);
        bidder2.doApprove(manager, 1000 * T2, t2);
    }
    function newReverseAuction() returns (uint, uint) {
        return manager.newReverseAuction(seller,  // beneficiary
                                         t1,      // selling
                                         t2,      // buying
                                         100 * T1,// sell amount (t1)
                                         5 * T2,  // minimum bid (t2)
                                         2 * T1,  // minimum increase
                                         1 years  // duration
                                         );
    }
    function testNewReverseAuction() {
        var (id, base) = newReverseAuction();

        assertEq(manager.getCollectMax(id), 0);
        assertEq(manager.isReversed(id), true);

        var (auction_id, last_bidder,
             last_bid, quantity) = manager.getAuctionlet(base);

        assertEq(auction_id, 1);
        assertEq(last_bidder, manager);
        assertEq(last_bid, 5 * T2);
        assertEq(quantity, 100 * T1);
    }
    function testNewReverseAuctionTransfersFromSeller() {
        var seller_t1_balance_before = t1.balanceOf(seller);
        var (id, base) = newReverseAuction();
        var seller_t1_balance_after = t1.balanceOf(seller);

        assertEq(seller_t1_balance_before - seller_t1_balance_after, 100 * T1);
    }
    function testBidTransfersFromBidder() {
        var (id, base) = newReverseAuction();

        var bidder_t2_balance_before = t2.balanceOf(bidder1);
        bidder1.doBid(base, 90 * T1);
        var bidder_t2_balance_after = t2.balanceOf(bidder1);

        // bidder should have reduced funds
        assertEq(bidder_t2_balance_before - bidder_t2_balance_after, 5 * T2);
    }
    function testBidTransfersToManager() {
        var (id, base) = newReverseAuction();

        var auction_t2_balance_before = t2.balanceOf(manager);
        bidder1.doBid(base, 90 * T1);
        var auction_t2_balance_after = t2.balanceOf(manager);

        // auction should have increased funds
        assertEq(auction_t2_balance_after - auction_t2_balance_before, 5 * T2);
    }
    function testFailFirstBidOverStartBid() {
        var (id, base) = newReverseAuction();
        bidder1.doBid(base, 105 * T1);
    }
    function testFailNextBidUnderMinimum() {
        var (id, base) = newReverseAuction();
        bidder1.doBid(base, 90 * T1);
        bidder1.doBid(base, 89 * T1);
    }
    function testFailNextBidUnderLast() {
        var (id, base) = newReverseAuction();
        bidder1.doBid(base, 90 * T1);
        bidder1.doBid(base, 91 * T1);
    }
    function testNextBidRefundsPreviousBidder() {
        var (id, base) = newReverseAuction();

        var bidder_t2_balance_before = t2.balanceOf(bidder1);
        bidder1.doBid(base, 90 * T1);
        bidder2.doBid(base, 85 * T1);
        var bidder_t2_balance_after = t2.balanceOf(bidder1);

        // bidder should have reduced funds
        assertEq(bidder_t2_balance_before - bidder_t2_balance_after, 0);
    }
}