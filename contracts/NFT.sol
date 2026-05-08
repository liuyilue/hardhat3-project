// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract NFT is ERC721, ERC721URIStorage, Ownable {
    uint256 private _tokenIdCounter;

    constructor() ERC721("AuctionNFT", "ANFT") Ownable(msg.sender) {
        _tokenIdCounter = 0;
    }

    function safeMint(address to, string memory uri) public onlyOwner returns (uint256) {
        uint256 tokenId = _tokenIdCounter;
        _tokenIdCounter++;
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, uri);
        return tokenId;
    }

    function burn(uint256 tokenId) public {
        address owner = ownerOf(tokenId);
        require(msg.sender == owner || isApprovedForAll(owner, msg.sender) || getApproved(tokenId) == msg.sender, 
                "ERC721: caller is not token owner or approved");
        _burn(tokenId);
    }

    function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721URIStorage) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
