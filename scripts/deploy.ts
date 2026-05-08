import { ethers, upgrades } from "hardhat";

async function main() {
  const [deployer] = await ethers.getSigners();
  console.log("Deploying contracts with the account:", deployer.address);
  console.log("Account balance:", (await deployer.provider.getBalance(deployer.address)).toString());

  const NFT = await ethers.getContractFactory("NFT");
  const nft = await NFT.deploy();
  await nft.waitForDeployment();
  console.log("NFT Contract deployed to:", await nft.getAddress());

  const ethUsdPriceFeed = "0x694AA1769357215DE4FAC081bf1f309aDC325306";
  const erc20UsdPriceFeed = "0x694AA1769357215DE4FAC081bf1f309aDC325306";

  const Auction = await ethers.getContractFactory("Auction");
  const auction = await upgrades.deployProxy(Auction, [ethUsdPriceFeed, erc20UsdPriceFeed]);
  await auction.waitForDeployment();
  console.log("Auction Contract deployed to:", await auction.getAddress());
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
