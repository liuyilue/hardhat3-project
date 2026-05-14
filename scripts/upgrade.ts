// 从 Hardhat 导入网络模块，用于创建 ethers 实例
import { network } from "hardhat";

async function main() {
  // 使用当前网络上下文创建 ethers 实例
  const { ethers } = (await network.create()) as any;
  // 获取当前部署者账户（第一个签名者）
  const [deployer] = await ethers.getSigners();

  // 从环境变量或命令行参数读取旧代理地址
  const proxyAddress = process.env.PROXY_ADDRESS || process.argv[2];
  // 读取可选版本号参数，默认值为 2
  const versionNumber = process.argv[3] || "2";

  // 如果未提供代理地址，则报错并停止执行
  if (!proxyAddress) {
    throw new Error("Missing proxy address. Provide it as the first script argument or set PROXY_ADDRESS in env.");
  }

  console.log("Upgrading proxy at:", proxyAddress);
  console.log("Using deployer:", deployer.address);

  // 获取 AuctionV2 合约工厂，用于部署新的实现合约
  const AuctionV2 = await ethers.getContractFactory("AuctionV2", deployer);
  const auctionV2Implementation = await AuctionV2.deploy();
  // 等待 AuctionV2 实现合约完成部署
  await auctionV2Implementation.waitForDeployment();

  console.log("AuctionV2 implementation deployed to:", await auctionV2Implementation.getAddress());

  // 通过实现合约的 ABI 附加旧代理地址，使得后续调用会通过代理执行
  const proxy = AuctionV2.attach(proxyAddress);

  console.log("Sending upgradeTo transaction...");
  // 调用代理合约的 upgradeTo 方法，将代理指向新的实现合约地址
  const upgradeTx = await proxy.upgradeTo(await auctionV2Implementation.getAddress());
  await upgradeTx.wait();
  console.log("Proxy upgraded to AuctionV2 implementation.");

  console.log("Calling initializeV2 on proxy...");
  // 如果 V2 版本需要额外初始化，则通过代理调用 initializeV2
  const initializeTx = await proxy.initializeV2(+versionNumber);
  await initializeTx.wait();
  console.log("initializeV2 completed with version:", versionNumber);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });