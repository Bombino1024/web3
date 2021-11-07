// SPDX-Licence-Identifier: MIT

pragma solidity >=0.6.6 <0.9.0;

// GET THE LATEST PRICE
// - downlad contract: https://docs.chain.link/docs/get-the-latest-price/
// - get faucet of konan
// - deploy above Smart Contract to Konan network

// google: npm @chainlink/contracts
// github: https://github.com/smartcontractkit/chainlink
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol"; 
import "@chainlink/contracts/src/v0.6/vendor/SafeMathChainlink.sol";
// https://docs.openzeppelin.com/contracts/4.x/ 
// openzeppelin - open source tool that allows us to use many prebuild contracts

contract FundMe {
    using SafeMathChainlink for uint256; // prevents from overflow
    
    mapping(address => uint256) public addressToAmountFunded;
    address public owner;
    address[] public funders;
    
    constructor() public {
        // set deployer address to owner
        owner = msg.sender;
    }
    
    // payable - this function can be used to pay for things
    // value - every transaction has a value
    // sender - sender address
    function fund() public payable {
        uint256 minimumUSD = 50 * 10 ** 18; // in wei
        // if require crashes -> the transaction would be reverted
        // second arguement is error message -> visible on ether scan
        require(getConversionRate(msg.value) >= minimumUSD, "You need to spend more ETH!"); 
        addressToAmountFunded[msg.sender] += msg.value;
        funders.push(msg.sender);
    }
    
    function getVersion() public view returns (uint256) {
        // zober interface AggregatorV3Interface z chainlinku (solidity potrebuje function signatures)
        // a napln jeho metody implementaciou na 0x8A753747A1Fa494EC906cE90E9f37563A8AF630e
        // addresses of implementation: https://docs.chain.link/docs/ethereum-addresses/
        AggregatorV3Interface priceFeed = AggregatorV3Interface(0x8A753747A1Fa494EC906cE90E9f37563A8AF630e);
        return priceFeed.version();
    }
    
    function getPrice() public view returns (uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(0x8A753747A1Fa494EC906cE90E9f37563A8AF630e);
        // store result of latestRoundData to a tuple
        (,int256 answer,,,) = priceFeed.latestRoundData();
        // solidity doesnt have decimal points
        // answer = current_price * 10^8 (8 decimal places)
        // 1 eth = 1000000000 gwei = 1000000000000000000 (*10^18) wei 
        return uint256(answer * 10000000000); // now to price is in wei
    }
    
    // transfer value of eth to US dollars
    function getConversionRate(uint256 ethAmount) public view returns(uint256) {
        uint256 ethPrice = getPrice();
        uint256 ethAmountInUsd = (ethPrice * ethAmount); // in wei
        ethAmountInUsd = ethAmountInUsd / 1000000000000000000; // 10^18
        return ethAmountInUsd; // returns value of entered amount in USD
    }
    
    modifier onlyOwner {
        require(msg.sender == owner);
        _; 
    }
    
    // onlyOwner will run before executing
    function withdraw() payable onlyOwner public {
        payable(msg.sender).transfer(address(this).balance);
        
        for(uint256 i = 0; i < funders.length; i++){
            address funder = funders[i];
            addressToAmountFunded[funder] = 0;
        }
        funders = new address[](0);
    }
}