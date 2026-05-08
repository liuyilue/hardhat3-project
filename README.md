# NFT 拍卖市场项目

基于 Hardhat 3.4.4 框架开发的 NFT 拍卖市场智能合约项目。

## 技术栈

- **框架**: Hardhat 3.4.4
- **语言**: Solidity 0.8.24
- **部署**: Viem / Ethers
- **升级模式**: UUPS Proxy
- **价格预言机**: Chainlink Price Feed

## 项目结构

```
nft-auction-market/
├── contracts/
│   ├── NFT.sol          # ERC721 NFT 合约
│   ├── Auction.sol      # 拍卖主合约（支持升级）
│ 
│   
│ 
├── scripts/
│   └── deploy.ts        # 部署脚本
├── test/
│   └── auction.test.ts  # 测试文件
├── hardhat.config.ts    # Hardhat 配置
├── package.json         # 依赖配置
└── README.md            # 项目说明
```

## 功能特性

### NFT 合约 (`NFT.sol`)

- ERC721 标准实现
- 支持 mint 功能
- 支持 burn 功能
- Ownable 权限控制

### 拍卖合约 (`Auction.sol`)

- **ETH 拍卖**: 支持以太币出价
- **ERC20 拍卖**: 支持 ERC20 代币出价
- **Chainlink 集成**: 获取 ETH/USD 和 ERC20/USD 价格
- **UUPS 升级**: 支持合约升级
- **竞拍功能**: 出价、取消、结算
- **时间控制**: 拍卖开始/结束时间

## 安装依赖

```bash
npm install --legacy-peer-deps
```

## 编译合约

```bash
npx hardhat compile
```

## 部署合约

### 本地部署

1. 启动 Hardhat 节点：

```bash
npx hardhat node
```

1. 在另一个终端运行部署脚本：

```bash
npx hardhat run scripts/deploy.ts --network localhost
```

### 测试网部署

在 `hardhat.config.ts` 中配置测试网参数后运行：

```bash
npx hardhat run scripts/deploy.ts --network sepolia
```

## 合约交互

### 启动拍卖

```typescript
await auction.createAuction(
  nftContractAddress,
  tokenId,
  startTime,
  endTime,
  isErc20,
  erc20TokenAddress
);
```

### 出价

```typescript
// ETH 出价
await auction.bid(auctionId, { value: ethAmount });

// ERC20 出价
await auction.bidWithERC20(auctionId, erc20Amount);
```

### 结算拍卖

```typescript
await auction.endAuction(auctionId);
```

## 测试

```bash
npx hardhat test
```

## Chainlink 价格 Feed 地址

- **ETH/USD**: `0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419` (主网)
- **ERC20/USD**: 根据具体代币配置

## 升级合约

```typescript
const AuctionV2 = await ethers.getContractFactory("AuctionV2");
await upgrades.upgradeProxy(auctionAddress, AuctionV2);
```

## 注意事项

1. 部署前确保已启动本地节点或配置正确的网络参数
2. Chainlink 价格 Feed 仅在主网和测试网上可用
3. 建议在正式部署前进行充分测试
4. UUPS 升级需要合约拥有者权限

## 许可证

MIT License
