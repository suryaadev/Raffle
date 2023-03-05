// enter lottery with paying some amt
// pick random winner (verifiable randomly)
// winner should be selected every X min ---> automate this
// chainlink oracle with randomness, automation(chainlink keeper)

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AutomationCompatibleInterface.sol";


error Raffle__NotEnoughETHEntered();
error Raffle__TransferFailed();

contract Raffle is VRFConsumerBaseV2{

    // state variables
    uint256 private immutable i_entaranceFee;
    address payable[] private s_players;
    VRFCoordinatorV2Interface private immutable i_vrfCoordinator;
    bytes32 private immutable i_gasLane;
    uint64 private immutable i_subscriptionId;
    uint32 private immutable i_callbackGasLimit;
    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    uint32 private constant NUM_WORDS = 1;

    // lottery valiables
    address private s_recentWinner; 
    
    
    /** Events */
    // when we update any dynamic object we should emit the event
    // naming convention for event names enter in reverse order as a function name
    
    event RaffleEnter(address indexed player);
    event RequestedRaffleWinner(uint256 indexed requestId);
    event WinnerPicked(address indexed winner);


    constructor(address vrfCoordinatorV2, uint256 entaranceFee, bytes32 gasLane, uint64 subscriptionId, uint32 callbackGasLimit) VRFConsumerBaseV2(vrfCoordinatorV2){
        i_entaranceFee = entaranceFee;
        i_vrfCoordinator = VRFCoordinatorV2Interface(vrfCoordinatorV2);
        i_gasLane = gasLane;
        i_subscriptionId = subscriptionId;
        i_callbackGasLimit = callbackGasLimit;
    }
    
    function enterRaffle() public payable{
        // require() string in require consumes more gas
        if(msg.value < i_entaranceFee){
            revert Raffle__NotEnoughETHEntered();
        }
        s_players.push(payable(msg.sender));
        emit RaffleEnter(msg.sender);

    } 

// req number
// act on it
// external consumes less gas 
    function requestRandomWinner() external{
        
        uint256 requestId = i_vrfCoordinator.requestRandomWords(
            i_gasLane, //keyHash
            i_subscriptionId,
            REQUEST_CONFIRMATIONS,
            i_callbackGasLimit,
            NUM_WORDS
        );

        emit RequestedRaffleWinner(requestId);
    }
    
    // we have to provide requestId but it goes silent in function so just remove the name
    function fulfillRandomWords(uint256 , uint256[] memory randomWords) internal override {
        
        uint256 indexOfWinner = randomWords[0] % s_players.length;
        address payable recentWinner = s_players[indexOfWinner];
        s_recentWinner = recentWinner;
        (bool sucess, ) = recentWinner.call{value : address(this).balance}("");
        if(!sucess){
            revert Raffle__TransferFailed();
        }
        emit WinnerPicked(recentWinner);
    }

    

/**view / pure functions */

    function getEntaranceFee() public view returns(uint256){
        return i_entaranceFee; 
    }

    function getPlayer(uint256 index) public view returns(address){
        return s_players[index];
    }

    function getRecentWinner() public view returns(address){
        return s_recentWinner;
    }


        
}
