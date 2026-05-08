// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "./Auction.sol";

contract AuctionV2 is Auction {
    function version() public pure returns (string memory) {
        return "2";
    }
}
