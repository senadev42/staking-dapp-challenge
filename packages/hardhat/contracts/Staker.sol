// SPDX-License-Identifier: MIT
pragma solidity 0.8.4; //Do not change the solidity version as it negativly impacts submission grading

import "hardhat/console.sol";
import "./ExampleExternalContract.sol";

contract Staker {
    address public owner;
    ExampleExternalContract public exampleExternalContract;


    ///Public Variables

    //mappings to keep track of data
    mapping(address => uint256) public balances;
    mapping(address => uint256) public depositTimeStamps;

    //Constants
    uint256 public constant rewardRatePerSecond = 0.1 ether;
    uint256 public withdrawalDeadline = block.timestamp + 120 seconds;
    uint256 public claimDeadline = block.timestamp + 240 seconds;
    uint256 public currentBlock = 0;

    ///Events
    event Stake(address indexed sender, uint256 amount);
    event Received(address, uint);
    event Execute(address indexed sender, uint256 amount);

    //Constructor
    constructor(address exampleExternalContractAddress) {
        owner = msg.sender;
        exampleExternalContract = ExampleExternalContract(
            exampleExternalContractAddress
        );
    }

    //Time Functions
    function withdrawalTimeLeft()
        public
        view
        returns (uint withdrawalTimeLeft)
    {
        if (block.timestamp >= withdrawalDeadline) {
            return (0);
        } else {
            return (withdrawalDeadline - block.timestamp);
        }
    }

    function claimPeriodLeft() public view returns (uint claimPeriodLeft) {
        if (block.timestamp >= claimDeadline) {
            return (0);
        } else {
            return (claimDeadline - block.timestamp);
        }
    }

    //Modifiers
    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    modifier withdrawalDeadlineReached(bool requireReached) {
        uint256 timeRemaining = withdrawalTimeLeft();
        if (requireReached) {
            require(timeRemaining == 0, "Withdrawal period is not reached yet");
        } else {
            require(timeRemaining > 0, "Withdrawal period has been reached");
        }
        _;
    }
    modifier claimDeadlineReached(bool requireReached) {
        uint256 timeRemaining = claimPeriodLeft();
        if (requireReached) {
            require(timeRemaining == 0, "Claim deadline is not reached yet");
        } else {
            require(timeRemaining > 0, "Claim deadline has been reached");
        }
        _;
    }

    // modifier notCompleted() {
    //     bool completed = exampleExternalContract.completed();
    //     require(!completed, "Stake already completed!");
    //     _;
    // }

    //Core Functions

    //depositing/'staking'
    function stake()
        public
        payable
        withdrawalDeadlineReached(false)
        claimDeadlineReached(false)
    {
        //update the balances array by concat
        balances[msg.sender] = balances[msg.sender] + msg.value;
        //update the timestamps array
        depositTimeStamps[msg.sender] = block.timestamp;
        // emit event
        emit Stake(msg.sender, msg.value);
    }

    function rewardOwed() public view returns (uint256 rewardOwed) {
        uint256 timeElapsed = block.timestamp - depositTimeStamps[msg.sender];
        uint a = 1015;
        uint b = a / 1000;
        return ((b**timeElapsed) + 6);
    }

    //only owner can call this
    function reset() public onlyOwner {
        //return the ether
        exampleExternalContract.returnfunds(payable(address(this)));

        //reset the time
        withdrawalDeadline = block.timestamp + 120 seconds;
        claimDeadline = block.timestamp + 240 seconds;
    }

    //withdrawing
    function withdraw()
        public
        withdrawalDeadlineReached(true)
        claimDeadlineReached(false)
    {
        //check if address qualifies
        require(
            balances[msg.sender] > 0,
            "You don't have anything to withdraw"
        );

     
        //exponential
        uint256 indRewards = balances[msg.sender] + rewardOwed();

        //update balances
        balances[msg.sender] = 0;

        //Then send rewards
        (bool sent, bytes memory data) = msg.sender.call{value: indRewards}("");

        require(
            sent,
            "RIP; withdrawal failed. We don't have enough money to give you. "
        );
    }

    //claiming any unwithdrawn funds

    function execute() public claimDeadlineReached(true) {
        exampleExternalContract.complete{value: address(this).balance}();
    }

    //to fund the contract
    receive() external payable {}
}
