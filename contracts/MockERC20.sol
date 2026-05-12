// SPDX 许可证标识符，声明合约使用 MIT 许可证
// SPDX-License-Identifier: MIT

// 指定 Solidity 编译器版本，要求版本在 0.8.24 及以上
pragma solidity ^0.8.24;

// 导入 OpenZeppelin 的 ERC20 标准代币合约，用于实现 ERC20 代币功能
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

// 导入 OpenZeppelin 的 Ownable 合约，用于实现所有权管理
import "@openzeppelin/contracts/access/Ownable.sol";

// 定义 MockERC20 合约，继承 ERC20（提供代币功能）和 Ownable（提供所有权控制）
contract MockERC20 is ERC20, Ownable {
    // 构造函数，在部署合约时调用，初始化代币名称、符号，并设置部署者为所有者
    constructor(string memory name, string memory symbol) ERC20(name, symbol) Ownable(msg.sender) {}

    // mint 函数，允许合约所有者铸造新的代币给指定地址
    // 参数：to - 接收代币的地址，amount - 铸造的数量
    // 修饰符 onlyOwner 确保只有所有者可以调用此函数
    function mint(address to, uint256 amount) public onlyOwner {
        // 调用 ERC20 内部的 _mint 函数，铸造代币
        _mint(to, amount);
    }
}
