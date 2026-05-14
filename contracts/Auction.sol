// SPDX 许可证标识符，声明合约使用 MIT 许可证
// SPDX-License-Identifier: MIT

// 指定 Solidity 编译器版本，要求 0.8.24 及以上版本
pragma solidity ^0.8.24;

// 导入可升级合约支持库
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

// 导入 ERC721 和 ERC20 接口，用于 NFT 和代币交互
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// 导入 Chainlink 价格喂价接口，用于获取 USD 价格
import "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

// 定义 Auction 合约，支持可升级代理模式
contract Auction is Initializable, UUPSUpgradeable, OwnableUpgradeable {
    // 拍卖项结构体，保存单个 NFT 拍卖的信息
    struct AuctionItem {
        uint256 auctionId;         // 拍卖 ID
        address nftContract;       // NFT 合约地址
        uint256 tokenId;           // NFT Token ID
        address seller;            // 卖家地址
        uint256 startTime;         // 开始时间
        uint256 endTime;           // 结束时间
        uint256 highestBid;        // 当前最高出价
        address highestBidder;     // 当前最高出价者
        bool isActive;             // 拍卖是否仍然有效
        bool isErc20;              // 是否使用 ERC20 代币出价
        address erc20Token;        // ERC20 代币地址（如果 isErc20 为 true）
    }

    // 存储所有拍卖项，key 为 auctionId
    mapping(uint256 => AuctionItem) public auctions;
    // 下一个拍卖 ID，自增使用
    uint256 public nextAuctionId;

    // Chainlink 价格喂价接口，分别用于 ETH/USD 和 ERC20/USD
    AggregatorV3Interface public ethUsdPriceFeed;
    AggregatorV3Interface public erc20UsdPriceFeed;

    // 事件：拍卖创建
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

    // 事件：出价
    event BidPlaced(
        uint256 indexed auctionId,
        address indexed bidder,
        uint256 amount,
        bool isErc20
    );

    // 事件：拍卖结束
    event AuctionEnded(
        uint256 indexed auctionId,
        address indexed winner,
        uint256 amount
    );

    // 初始化函数，只能在代理部署后调用一次
    function initialize(address _ethUsdPriceFeed, address _erc20UsdPriceFeed) initializer public {
        __Ownable_init(msg.sender); // 初始化 OwnableUpgradeable，并设置合约所有者为部署者
        // __UUPSUpgradeable_init();  // UUPSUpgradeable 目前不需要单独初始化
        ethUsdPriceFeed = AggregatorV3Interface(_ethUsdPriceFeed);
        erc20UsdPriceFeed = AggregatorV3Interface(_erc20UsdPriceFeed);
        nextAuctionId = 1; // 拍卖 ID 从 1 开始
    }

    // UUPS 升级权限控制，只允许合约所有者执行升级
    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    // 创建拍卖
    function createAuction(
        address nftContract,
        uint256 tokenId,
        uint256 duration,
        bool isErc20,
        address erc20Token
    ) external {
        IERC721 nft = IERC721(nftContract);
        // 仅 NFT 拥有者可以创建拍卖
        require(nft.ownerOf(tokenId) == msg.sender, "Auction: Not NFT owner");
        // 合约必须获得 NFT 的授权，否则无法转移 NFT
        require(
            nft.getApproved(tokenId) == address(this) ||
            nft.isApprovedForAll(msg.sender, address(this)),
            "Auction: Contract not approved"
        );

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

        // 将 NFT 转入合约托管
        nft.transferFrom(msg.sender, address(this), tokenId);

        emit AuctionCreated(auctionId, nftContract, tokenId, msg.sender, startTime, endTime, isErc20, erc20Token);
    }

    // 出价
    function placeBid(uint256 auctionId) external payable {
        AuctionItem storage auction = auctions[auctionId];
        require(auction.isActive, "Auction: Not active");
        require(block.timestamp < auction.endTime, "Auction: Ended");
        require(msg.sender != auction.seller, "Auction: Seller cannot bid");

        uint256 bidAmount;
        bool isErc20Bid = auction.isErc20;

        if (isErc20Bid) {
            // ERC20 出价逻辑：必须先批准合约转移代币
            require(msg.value == 0, "Auction: Use ERC20 token");
            bidAmount = IERC20(auction.erc20Token).allowance(msg.sender, address(this));
            require(bidAmount > auction.highestBid, "Auction: Bid too low");
            IERC20(auction.erc20Token).transferFrom(msg.sender, address(this), bidAmount);
        } else {
            // ETH 出价逻辑，直接支付 ETH
            require(msg.value > auction.highestBid, "Auction: Bid too low");
            bidAmount = msg.value;
        }

        // 如果已有最高出价者，则退还上一位出价者
        if (auction.highestBidder != address(0)) {
            _refundPreviousBidder(auction);
        }

        auction.highestBid = bidAmount;
        auction.highestBidder = msg.sender;

        emit BidPlaced(auctionId, msg.sender, bidAmount, isErc20Bid);
    }

    // 内部函数：退还上一位出价者
    function _refundPreviousBidder(AuctionItem storage auction) internal {
        if (auction.isErc20) {
            IERC20(auction.erc20Token).transfer(auction.highestBidder, auction.highestBid);
        } else {
            payable(auction.highestBidder).transfer(auction.highestBid);
        }
    }

    // 结束拍卖
    function endAuction(uint256 auctionId) external {
        AuctionItem storage auction = auctions[auctionId];
        require(auction.isActive, "Auction: Not active");
        require(block.timestamp >= auction.endTime, "Auction: Not ended");

        auction.isActive = false;

        if (auction.highestBidder != address(0)) {
            // 将 NFT 发送给最高出价者
            IERC721(auction.nftContract).transferFrom(address(this), auction.highestBidder, auction.tokenId);
            // 将资金发送给卖家
            if (auction.isErc20) {
                IERC20(auction.erc20Token).transfer(auction.seller, auction.highestBid);
            } else {
                payable(auction.seller).transfer(auction.highestBid);
            }
        } else {
            // 如果无人出价，将 NFT 返回给卖家
            IERC721(auction.nftContract).transferFrom(address(this), auction.seller, auction.tokenId);
        }

        emit AuctionEnded(auctionId, auction.highestBidder, auction.highestBid);
    }

    // 获取最新 ETH/USD 价格
    function getLatestEthUsdPrice() public view returns (int256) {
        (, int256 price, , , ) = ethUsdPriceFeed.latestRoundData();
        return price;
    }

    // 获取最新 ERC20/USD 价格
    function getLatestErc20UsdPrice() public view returns (int256) {
        (, int256 price, , , ) = erc20UsdPriceFeed.latestRoundData();
        return price;
    }

    // 将 ETH 数量转换为 USD 值
    function convertEthToUsd(uint256 ethAmount) public view returns (uint256) {
        int256 price = getLatestEthUsdPrice();
        return uint256(price) * ethAmount / 1e18;
    }

    // 将 ERC20 代币数量转换为 USD 值
    function convertErc20ToUsd(uint256 erc20Amount) public view returns (uint256) {
        int256 price = getLatestErc20UsdPrice();
        return uint256(price) * erc20Amount / 1e18;
    }
}
