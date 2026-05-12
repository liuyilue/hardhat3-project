import { expect } from "chai";
import { network } from "hardhat";

const { ethers } = (await network.create()) as any;

describe("NFT Contract", function () {
  let nft: any;
  let owner: any;
  let addr1: any;

  // 每个测试用例前部署新的 NFT 合约
  beforeEach(async function () {
    [owner, addr1] = await ethers.getSigners();
    const NFTFactory = await ethers.getContractFactory("NFT");
    nft = await NFTFactory.deploy();
    await nft.waitForDeployment();
  });

  // 测试：铸造 NFT 给合约拥有者
  it("Should mint NFT to owner", async function () {
    const tokenId = await nft.safeMint(owner.address, "https://example.com/token/1");
    await tokenId.wait();
    
    expect(await nft.ownerOf(0)).to.equal(owner.address);
    expect(await nft.tokenURI(0)).to.equal("https://example.com/token/1");
  });

  // 测试：铸造 NFT 给另一个地址
  it("Should mint NFT to another address", async function () {
    await nft.safeMint(addr1.address, "https://example.com/token/1");
    
    expect(await nft.ownerOf(0)).to.equal(addr1.address);
  });

  // 测试：销毁已铸造的 NFT
  it("Should burn NFT", async function () {
    await nft.safeMint(owner.address, "https://example.com/token/1");
    await nft.burn(0);

    await expect(nft.ownerOf(0)).to.revert(ethers);
  });

  // 测试：将 NFT 从拥有者转移到另一个地址
  it("Should transfer NFT", async function () {
    await nft.safeMint(owner.address, "https://example.com/token/1");
    await nft.transferFrom(owner.address, addr1.address, 0);
    
    expect(await nft.ownerOf(0)).to.equal(addr1.address);
  });
});
