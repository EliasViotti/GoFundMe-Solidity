//Get funds from users because im poor
//Withdraw funds
//Set a minimum funding value in USD

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

error NotOwner();

library PriceConverter {
    //libraries cant have state vars and all functions are internal

    function getPrice() internal view returns (uint256) {
        //for us to get the price we need
        //Address from the contract  -- 0x694AA1769357215DE4FAC081bf1f309aDC325306
        //ABI from the contract

        AggregatorV3Interface priceFeed = AggregatorV3Interface(0xfEefF7c3fB57d18C5C6Cdd71e45D2D0b4F9377bF);
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
    
}

//726.081  gas used 
//709.644 
contract FundMe {
    using PriceConverter for uint256; //all uint256 have access to our library

    uint256 public constant MINIMUN_USD = 5e18;

    address[] public funders;   
    mapping(address funder => uint256 amountFunded) public addressToAmountFunded;

    address public immutable i_owner;

    constructor(){
        i_owner = msg.sender;
    }

    receive() external payable {
        fund();
    }

    fallback() external payable {
        fund();
    }
    
    //function that allows users to send a minimum of 5 dollars in ETH or more
    function fund() public payable {
        /*msg.value gets taken as the first parameter in getConversionRate, thats why the () are empty
        if getConversionRate had 2 parameters, that 2nd one would go between the ()*/
        require(msg.value.getConversionRate() >= MINIMUN_USD, "Didn't send enough ETH" ); //1e18 = 1ETH in WEI = 1000000000000000000 
        /*this is how low lvl process numbers, in wei format
        gas cost is shown in Gwei*/

        /*A "revert" undo any actions that have been done, and send the remaining gas back
        bassically, goes back the lines to undo if a next line fails a requirement or has an error*/
        funders.push(msg.sender);
        addressToAmountFunded[msg.sender] += msg.value;
    }

    function getVersion() internal view returns (uint256) {
        return
            AggregatorV3Interface(0xfEefF7c3fB57d18C5C6Cdd71e45D2D0b4F9377bF) //ZKSync sepolia
                .version();
    }

    function withdraw () public onlyOwner {
        for(uint256 funderIndex = 0; funderIndex < funders.length; funderIndex++){
            address funder = funders[funderIndex];
            addressToAmountFunded[funder] = 0;
        }

        funders = new address[](0); //new keyword to reset the array to a brand new blank one
        /*
        //TRANSFER
        //msg.sender = address
        //payable(msg.sender) = payable address
        payable(msg.sender).transfer(address(this).balance); //we type cast msg.sender to payable
        //if this fails, throws error and returns gas

        //SEND
        bool sendSucces = payable(msg.sender).send(address(this).balance);
        require(sendSucces, "Send Failed!");
        */
        //CALL
        //call can call any function in all ethereum, we are just using it like a transaction
        (bool callSuccess, /*bytes memory dataReturned*/) = payable(msg.sender).call{value: address(this).balance}("");
        require(callSuccess, "Call Failed!");
    }

    modifier onlyOwner() {
        //require(msg.sender == i_owner, "Sender is not the owner!");
        if(msg.sender != i_owner) { revert NotOwner(); } //revert is like require but without the condition
        _; //the position of the "_" tells the function if needs to execute the function first and then the modifier
        //in case we need to execute function first, "_" must be the first line in the body of the modifier
        //in this case, we are telling the function to execute the modifier first and then the function
    }

    //when someone sends money to the contract without calling fund function, we have 2 special functions
    // recieve()
    // fallback() 
}