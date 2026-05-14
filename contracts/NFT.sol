// SPDX 许可证标识符，声明合约使用 MIT 许可证
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

// 导入 OpenZeppelin 的 ERC721 标准实现
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
// 导入支持 NFT 元数据 URI 存储的扩展
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
// 导入 Ownable 合约，用于所有者权限控制
import "@openzeppelin/contracts/access/Ownable.sol";

// 定义 NFT 合约，继承 ERC721、ERC721URIStorage 和 Ownable
contract NFT is ERC721, ERC721URIStorage, Ownable {
    // 计数器，用于生成唯一的 tokenId
    uint256 private _tokenIdCounter;

    // 构造函数：设置 NFT 名称和符号，并初始化所有者和 tokenId 计数器
    constructor() ERC721("AuctionNFT", "ANFT") Ownable(msg.sender) {
        _tokenIdCounter = 0;
    }

    // 铸造新的 NFT
    // 只有合约所有者可以调用
    // to: 接收 NFT 的地址
    // uri: NFT 对应的元数据 URI
    function safeMint(address to, string memory uri) public onlyOwner returns (uint256) {
        uint256 tokenId = _tokenIdCounter; // 当前 tokenId
        _tokenIdCounter++; // 计数器自增，为下一个 NFT 准备
        _safeMint(to, tokenId); // 安全铸造 NFT，确保接收方支持 ERC721
        _setTokenURI(tokenId, uri); // 设置该 NFT 的 metadata URI
        return tokenId; // 返回新铸造的 tokenId
    }

    // 销毁指定 tokenId 的 NFT
    // 只有 NFT 拥有者或经过批准的地址可以调用
    function burn(uint256 tokenId) public {
        address owner = ownerOf(tokenId);
        require(
            msg.sender == owner ||
            isApprovedForAll(owner, msg.sender) ||
            getApproved(tokenId) == msg.sender,
            "ERC721: caller is not token owner or approved"
        );
        _burn(tokenId); // 执行销毁
    }

    // 重写 tokenURI，解决 ERC721 和 ERC721URIStorage 的继承冲突
    function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        return super.tokenURI(tokenId);
    }

    // 重写 supportsInterface，解决多个父合约接口支持查询冲突
    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721URIStorage) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
