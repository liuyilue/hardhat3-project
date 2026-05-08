// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

contract Auction is Initializable, UUPSUpgradeable, OwnableUpgradeable {
    struct AuctionItem {
        uint256 auctionId;
        address nftContract;
        uint256 tokenId;
        address seller;
        uint256 startTime;
        uint256 endTime;
        uint256 highestBid;
        address highestBidder;
        bool isActive;
        bool isErc20;
        address erc20Token;
    }

    mapping(uint256 => AuctionItem) public auctions;
    uint256 public nextAuctionId;

    AggregatorV3Interface public ethUsdPriceFeed;
    AggregatorV3Interface public erc20UsdPriceFeed;

    event AuctionCreated(
        uint256 indexed auctionId,
        address indexed nftContract,
        uint256 indexed tokenId,
        address seller,
        uint256 startTime,
        uint256 endTime,
        bool isErc20,
        address erc20Token
    );

    event BidPlaced(
        uint256 indexed auctionId,
        address indexed bidder,
        uint256 amount,
        bool isErc20
    );

    event AuctionEnded(
        uint256 indexed auctionId,
        address indexed winner,
        uint256 amount
    );

    function initialize(address _ethUsdPriceFeed, address _erc20UsdPriceFeed) initializer public {
        __Ownable_init(msg.sender);
        __UUPSUpgradeable_init();
        ethUsdPriceFeed = AggregatorV3Interface(_ethUsdPriceFeed);
        erc20UsdPriceFeed = AggregatorV3Interface(_erc20UsdPriceFeed);
        nextAuctionId = 1;
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    function createAuction(
        address nftContract,
        uint256 tokenId,
        uint256 duration,
        bool isErc20,
        address erc20Token
    ) external {
        IERC721 nft = IERC721(nftContract);
        require(nft.ownerOf(tokenId) == msg.sender, "Auction: Not NFT owner");
        require(nft.getApproved(tokenId) == address(this) || 
                nft.isApprovedForAll(msg.sender, address(this)), 
                "Auction: Contract not approved");

        uint256 auctionId = nextAuctionId++;
        uint256 startTime = block.timestamp;
        uint256 endTime = startTime + duration;

        auctions[auctionId] = AuctionItem({
            auctionId: auctionId,
            nftContract: nftContract,
            tokenId: tokenId,
            seller: msg.sender,
            startTime: startTime,
            endTime: endTime,
            highestBid: 0,
            highestBidder: address(0),
            isActive: true,
            isErc20: isErc20,
            erc20Token: erc20Token
        });

        nft.transferFrom(msg.sender, address(this), tokenId);

        emit AuctionCreated(auctionId, nftContract, tokenId, msg.sender, startTime, endTime, isErc20, erc20Token);
    }

    function placeBid(uint256 auctionId) external payable {
        AuctionItem storage auction = auctions[auctionId];
        require(auction.isActive, "Auction: Not active");
        require(block.timestamp < auction.endTime, "Auction: Ended");
        require(msg.sender != auction.seller, "Auction: Seller cannot bid");

        uint256 bidAmount;
        bool isErc20Bid = auction.isErc20;

        if (isErc20Bid) {
            require(msg.value == 0, "Auction: Use ERC20 token");
            bidAmount = IERC20(auction.erc20Token).allowance(msg.sender, address(this));
            require(bidAmount > auction.highestBid, "Auction: Bid too low");
            IERC20(auction.erc20Token).transferFrom(msg.sender, address(this), bidAmount);
        } else {
            require(msg.value > auction.highestBid, "Auction: Bid too low");
            bidAmount = msg.value;
        }

        if (auction.highestBidder != address(0)) {
            _refundPreviousBidder(auction);
        }

        auction.highestBid = bidAmount;
        auction.highestBidder = msg.sender;

        emit BidPlaced(auctionId, msg.sender, bidAmount, isErc20Bid);
    }

    function _refundPreviousBidder(AuctionItem storage auction) internal {
        if (auction.isErc20) {
            IERC20(auction.erc20Token).transfer(auction.highestBidder, auction.highestBid);
        } else {
            payable(auction.highestBidder).transfer(auction.highestBid);
        }
    }

    function endAuction(uint256 auctionId) external {
        AuctionItem storage auction = auctions[auctionId];
        require(auction.isActive, "Auction: Not active");
        require(block.timestamp >= auction.endTime, "Auction: Not ended");

        auction.isActive = false;

        if (auction.highestBidder != address(0)) {
            IERC721(auction.nftContract).transferFrom(address(this), auction.highestBidder, auction.tokenId);
            
            if (auction.isErc20) {
                IERC20(auction.erc20Token).transfer(auction.seller, auction.highestBid);
            } else {
                payable(auction.seller).transfer(auction.highestBid);
            }
        } else {
            IERC721(auction.nftContract).transferFrom(address(this), auction.seller, auction.tokenId);
        }

        emit AuctionEnded(auctionId, auction.highestBidder, auction.highestBid);
    }

    function getLatestEthUsdPrice() public view returns (int256) {
        (, int256 price, , , ) = ethUsdPriceFeed.latestRoundData();
        return price;
    }

    function getLatestErc20UsdPrice() public view returns (int256) {
        (, int256 price, , , ) = erc20UsdPriceFeed.latestRoundData();
        return price;
    }

    function convertEthToUsd(uint256 ethAmount) public view returns (uint256) {
        int256 price = getLatestEthUsdPrice();
        return uint256(price) * ethAmount / 1e18;
    }

    function convertErc20ToUsd(uint256 erc20Amount) public view returns (uint256) {
        int256 price = getLatestErc20UsdPrice();
        return uint256(price) * erc20Amount / 1e18;
    }
}
