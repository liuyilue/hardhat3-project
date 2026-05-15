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
  //const versionNumber = process.argv[3] || "2";

  const versionNumber = 2;

  // 如果未提供代理地址，则报错并停止执行
  if (!proxyAddress) {
    throw new Error("Missing proxy address. Provide it as the first script argument or set PROXY_ADDRESS in env.");
  }

  console.log("Upgrading proxy at:", proxyAddress);
  console.log("Using deployer:", deployer.address);

  // 获取 AuctionV2 合约工厂，用于部署新的实现合约
  const AuctionV2 = await ethers.getContractFactory("AuctionV2", deployer);

  // 先把旧代理地址附加到 AuctionV2 ABI。升级前可以读取 owner，升级后可以调用 V2 方法。
  const proxy = AuctionV2.attach(proxyAddress);

  const proxyOwner = await proxy.owner();
  console.log("Proxy owner:", proxyOwner);

  if (proxyOwner.toLowerCase() !== deployer.address.toLowerCase()) {
    throw new Error(
      `The deployer is not the proxy owner. Owner is ${proxyOwner}, deployer is ${deployer.address}.`
    );
  }

  const auctionV2Implementation = await AuctionV2.deploy();
  // 等待 AuctionV2 实现合约完成部署
  await auctionV2Implementation.waitForDeployment();

  const newImplementation = await auctionV2Implementation.getAddress();
  console.log("AuctionV2 implementation deployed to:", newImplementation);

  const initializeV2Data = AuctionV2.interface.encodeFunctionData("initializeV2", [
    +versionNumber,
  ]);

  console.log("Sending upgradeToAndCall transaction...");
  // OpenZeppelin 5.x 的 UUPSUpgradeable 只暴露 upgradeToAndCall。
  // 这里通过代理执行 delegatecall，并在同一笔交易里初始化 V2 新增状态。
  const upgradeTx = await proxy.upgradeToAndCall(newImplementation, initializeV2Data);
  await upgradeTx.wait();
  console.log("Proxy upgraded and initializeV2 completed with version:", versionNumber);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
