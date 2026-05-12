// SPDX 许可证标识符，声明合约使用 MIT 许可证
// SPDX-License-Identifier: MIT

// 指定 Solidity 编译器版本，要求版本在 0.8.24 及以上
pragma solidity ^0.8.24;

// 导入 OpenZeppelin 的 ERC1967Proxy 合约，用于实现透明代理模式，支持合约升级
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

// 定义 AuctionProxy 合约，继承 ERC1967Proxy，提供代理功能
contract AuctionProxy is ERC1967Proxy {
    // 构造函数，在部署代理合约时调用
    // 参数：implementation - 实现合约的地址，data - 初始化数据（用于调用实现合约的初始化函数）
    constructor(address implementation, bytes memory data) ERC1967Proxy(implementation, data) {}
}
