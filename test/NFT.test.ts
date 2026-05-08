import { expect } from "chai";
import { ethers } from "hardhat";
import { NFT } from "../typechain-types";

describe("NFT Contract", function () {
  let nft: NFT;
  let owner: any;
  let addr1: any;

  beforeEach(async function () {
    [owner, addr1] = await ethers.getSigners();
    const NFTFactory = await ethers.getContractFactory("NFT");
    nft = await NFTFactory.deploy();
    await nft.waitForDeployment();
  });

  it("Should mint NFT to owner", async function () {
    const tokenId = await nft.safeMint(owner.address, "https://example.com/token/1");
    await tokenId.wait();
    
    expect(await nft.ownerOf(0)).to.equal(owner.address);
    expect(await nft.tokenURI(0)).to.equal("https://example.com/token/1");
  });

  it("Should mint NFT to another address", async function () {
    await nft.safeMint(addr1.address, "https://example.com/token/1");
    
    expect(await nft.ownerOf(0)).to.equal(addr1.address);
  });

  it("Should burn NFT", async function () {
    await nft.safeMint(owner.address, "https://example.com/token/1");
    await nft.burn(0);
    
    await expect(nft.ownerOf(0)).to.be.revertedWith("ERC721: invalid token ID");
  });

  it("Should transfer NFT", async function () {
    await nft.safeMint(owner.address, "https://example.com/token/1");
    await nft.transferFrom(owner.address, addr1.address, 0);
    
    expect(await nft.ownerOf(0)).to.equal(addr1.address);
  });
});
