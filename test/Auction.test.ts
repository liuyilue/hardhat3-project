import { expect } from "chai";
import { network } from "hardhat";

const { ethers } = (await network.create()) as any;

// Auction 合约测试集
describe("Auction Contract", function () {
  let nft: any;
  let auction: any;
  let erc20: any;
  let owner: any;
  let seller: any;
  let bidder1: any;
  let bidder2: any;

  // 每个测试用例前的部署与初始化
  beforeEach(async function () {
    [owner, seller, bidder1, bidder2] = await ethers.getSigners();

    const NFTFactory = await ethers.getContractFactory("NFT");
    nft = await NFTFactory.deploy();
    await nft.waitForDeployment();

    const MockERC20Factory = await ethers.getContractFactory("MockERC20");
    erc20 = await MockERC20Factory.deploy("Mock Token", "MTK");
    await erc20.waitForDeployment();

    const mockEthUsdPriceFeed = "0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419";
    const mockErc20UsdPriceFeed = "0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419";

    const AuctionFactory = await ethers.getContractFactory("Auction");
    auction = await AuctionFactory.deploy();
    await auction.waitForDeployment();
    await auction.initialize(mockEthUsdPriceFeed, mockErc20UsdPriceFeed);
  });

  // 测试：创建一个新的拍卖
  it("Should create an auction", async function () {
    await nft.connect(owner).safeMint(seller.address, "https://example.com/token/1");
    await nft.connect(seller).approve(await auction.getAddress(), 0);

    await expect(auction.connect(seller).createAuction(
      await nft.getAddress(),
      0,
      3600,
      false,
      ethers.ZeroAddress
    )).to.emit(auction, "AuctionCreated");
  });

  // 测试：使用 ETH 进行竞价
  it("Should place a bid with ETH", async function () {
    await nft.connect(owner).safeMint(seller.address, "https://example.com/token/1");
    await nft.connect(seller).approve(await auction.getAddress(), 0);

    await auction.connect(seller).createAuction(
      await nft.getAddress(),
      0,
      3600,
      false,
      ethers.ZeroAddress
    );

    await expect(auction.connect(bidder1).placeBid(1, { value: ethers.parseEther("1") }))
      .to.emit(auction, "BidPlaced");

    const auctionData = await auction.auctions(1);
    expect(auctionData.highestBid).to.equal(ethers.parseEther("1"));
    expect(auctionData.highestBidder).to.equal(bidder1.address);
  });

  // 测试：使用 ERC20 代币进行竞价
  it("Should place a bid with ERC20", async function () {
    await erc20.mint(bidder1.address, ethers.parseEther("100"));
    await erc20.connect(bidder1).approve(await auction.getAddress(), ethers.parseEther("100"));

    await nft.connect(owner).safeMint(seller.address, "https://example.com/token/1");
    await nft.connect(seller).approve(await auction.getAddress(), 0);

    await auction.connect(seller).createAuction(
      await nft.getAddress(),
      0,
      3600,
      true,
      await erc20.getAddress()
    );

    await expect(auction.connect(bidder1).placeBid(1))
      .to.emit(auction, "BidPlaced");

    const auctionData = await auction.auctions(1);
    expect(auctionData.highestBid).to.equal(ethers.parseEther("100"));
  });

  // 测试：结束拍卖并将 NFT 转移给最高出价者
  it("Should end auction and transfer NFT to highest bidder", async function () {
    await nft.connect(owner).safeMint(seller.address, "https://example.com/token/1");
    await nft.connect(seller).approve(await auction.getAddress(), 0);

    await auction.connect(seller).createAuction(
      await nft.getAddress(),
      0,
      60,
      false,
      ethers.ZeroAddress
    );

    await auction.connect(bidder1).placeBid(1, { value: ethers.parseEther("1") });

    await ethers.provider.send("evm_increaseTime", [61]);
    await ethers.provider.send("evm_mine", []);

    await expect(auction.connect(owner).endAuction(1))
      .to.emit(auction, "AuctionEnded");

    expect(await nft.ownerOf(0)).to.equal(bidder1.address);
  });
});
