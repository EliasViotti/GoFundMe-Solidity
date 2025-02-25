// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

library PriceConverter {
    //libraries cant have state vars and all functions are internal

    function getPrice() internal view returns (uint256) {
        //for us to get the price we need
        //Address from the contract  -- 0x694AA1769357215DE4FAC081bf1f309aDC325306
        //ABI from the contract

        AggregatorV3Interface priceFeed = AggregatorV3Interface(0x694AA1769357215DE4FAC081bf1f309aDC325306);
        (, int256 price, , , ) = priceFeed.latestRoundData();
        //Price of ETH in terms of USD
        return uint256(price) * 1e10; //price is a int256 and msg.value is a uint256, we had to typecast it
        //we multiplied price times 1e10 to add the exact amount of ceros to match msg.value
    }

    function getConversionRate(uint256 ethAmount) internal view returns (uint256){
        uint256 ethPrice = getPrice();
        uint256 ethAmountInUsd = (ethPrice * ethAmount) / 1e18; //divide because of the amount of decimals
        return ethAmountInUsd;
    }
    
    function getVersion() internal view returns (uint256) {
        return
            AggregatorV3Interface(0x694AA1769357215DE4FAC081bf1f309aDC325306)
                .version();
    }
}
