// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

contract PriceConsumer {
    AggregatorV3Interface internal ethUsdPriceFeed;
    AggregatorV3Interface internal erc20UsdPriceFeed;

    constructor(address _ethUsdPriceFeed, address _erc20UsdPriceFeed) {
        ethUsdPriceFeed = AggregatorV3Interface(_ethUsdPriceFeed);
        erc20UsdPriceFeed = AggregatorV3Interface(_erc20UsdPriceFeed);
    }

    function getLatestEthUsdPrice() public view returns (int256) {
        (, int256 price, , , ) = ethUsdPriceFeed.latestRoundData();
        return price;
    }

    function getLatestErc20UsdPrice() public view returns (int256) {
        (, int256 price, , , ) = erc20UsdPriceFeed.latestRoundData();
        return price;
    }

    function convertEthToUsd(uint256 ethAmount) public view returns (uint256) {
        int256 price = getLatestEthUsdPrice();
        return uint256(price) * ethAmount / 1e18;
    }

    function convertErc20ToUsd(uint256 erc20Amount) public view returns (uint256) {
        int256 price = getLatestErc20UsdPrice();
        return uint256(price) * erc20Amount / 1e18;
    }
}
