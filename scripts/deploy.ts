// 导入 Hardhat 的 network 模块，用于网络配置和提供者
import { network } from "hardhat";

// 定义主部署函数
async function main() {
  // 从网络创建 ethers 实例，用于与区块链交互
  const { ethers } = (await network.create()) as any;

  // 获取部署者账户（第一个签名者）
  const [deployer] = await ethers.getSigners();

  // 打印部署者地址和账户余额
  console.log("Deploying contracts with the account:", deployer.address);
  console.log("Account balance:", (await deployer.provider.getBalance(deployer.address)).toString());

  // 部署 NFT 合约，使用 ethers.deployContract 方法
  const nft = await ethers.deployContract("NFT", [], deployer);
  // 等待部署完成
  await nft.waitForDeployment();
  // 打印 NFT 合约地址
  console.log("NFT Contract deployed to:", await nft.getAddress());

  // 定义 ETH/USD 和 ERC20/USD 价格喂价地址（这里使用相同的占位符地址）
  const ethUsdPriceFeed = "0x694AA1769357215DE4FAC081bf1f309aDC325306";
  const erc20UsdPriceFeed = "0x694AA1769357215DE4FAC081bf1f309aDC325306";

  // 获取 Auction 合约工厂
  const Auction = await ethers.getContractFactory("Auction", deployer);
  // 部署 Auction 实现合约
  const auctionImplementation = await Auction.deploy();
  // 等待部署完成
  await auctionImplementation.waitForDeployment();
  // 打印实现合约地址
  console.log("Auction implementation deployed to:", await auctionImplementation.getAddress());

  // 编码初始化函数数据，用于代理合约的初始化
  const initializeData = Auction.interface.encodeFunctionData("initialize", [
    ethUsdPriceFeed,
    erc20UsdPriceFeed,
  ]);
  console.log("initialize data:", initializeData);

  // 获取 AuctionProxy 合约工厂
  const Proxy = await ethers.getContractFactory("AuctionProxy", deployer);
  let auctionProxy;
  try {
    // 部署代理合约，传入实现合约地址和初始化数据
    auctionProxy = await Proxy.deploy(await auctionImplementation.getAddress(), initializeData);
    // 等待部署完成
    await auctionProxy.waitForDeployment();
  } catch (error) {
    console.error("Proxy deployment failed.");
    console.error(error);
    throw error;
  }

  // 将 Auction 合约附加到代理地址，以便通过代理调用
  const auction = Auction.attach(await auctionProxy.getAddress());
  // 打印代理合约地址
  console.log("Auction proxy deployed to:", await auction.getAddress());
}

// 执行主函数，如果成功则退出，否则打印错误并退出
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
