// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "./Auction.sol";

// AuctionV2 继承自 Auction，实现一个新的升级版本。
// 这个合约示例中只添加了一个简单的新功能（版本号），用于演示代理升级流程。
contract AuctionV2 is Auction {
    // 新增的状态变量，必须追加到父合约存储布局末尾，保证升级兼容性
    uint256 public versionNumber;

    // V2 初始化函数，用于在升级后设置新状态
    function initializeV2(uint256 _versionNumber) public reinitializer(2) {
        versionNumber = _versionNumber;
    }

    // 新增方法，返回当前实现的版本号
    function getVersionNumber() public view returns (uint256) {
        return versionNumber;
    }
}
