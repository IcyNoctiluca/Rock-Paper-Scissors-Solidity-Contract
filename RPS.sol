pragma solidity ^0.4.24;

contract RPS {

  // to map combinations of hands to the winner
  mapping (string => mapping(string => int)) outcomeMatrix;

  uint256 public initialStake;    // cannot be negative
  uint256 backingStake;

  address player1;
  address player2;
  address owner;

  string player1Hand;
  string player2Hand;
  string public player1HandPublic;
  string public player2HandPublic;

  int winner;       // -1 initally, 0 for draw, 1 for player1, 2 for p2
  uint public initialisedTime;


  constructor() public {

    owner = msg.sender;

    // initialise combinations
    outcomeMatrix["ROCK"]["ROCK"] = 0;
    outcomeMatrix["ROCK"]["PAPER"] = 2;
    outcomeMatrix["ROCK"]["SCISSORS"] = 1;
    outcomeMatrix["PAPER"]["ROCK"] = 1;
    outcomeMatrix["PAPER"]["PAPER"] = 0;
    outcomeMatrix["PAPER"]["SCISSORS"] = 2;
    outcomeMatrix["SCISSORS"]["ROCK"] = 2;
    outcomeMatrix["SCISSORS"]["PAPER"] = 1;
    outcomeMatrix["SCISSORS"]["SCISSORS"] = 0;

    // initialise other variables
    initialStake = 0;
    backingStake = 0;
    player1Hand = "";
    player2Hand = "";
    winner = -1;

  }

  function compareStrings(string a, string b) public pure returns (bool) {
      return keccak256(abi.encodePacked(a)) == keccak256(abi.encodePacked(b));
  }

  function initialiseStake() payable public {

    require(initialStake == 0 && msg.value > 0);
    initialisedTime = now;
    initialStake = msg.value;
    player1 = msg.sender;
  }

  function acceptStake() payable public {
    // require an stake to be initialised before it can be accepted
    // require same amount of ether as init awardStakes
    // cannot be called twice in a row
    require(initialStake != 0 && initialStake == msg.value && backingStake == 0);
    require(player1 != player2);     // player can't play against self

    player2 = msg.sender;
    backingStake = msg.value;
  }


  function setPlayer1Hand(string hand) public {

    require(msg.sender == player1);
    require(compareStrings(player1Hand, ""));         // cannot change hand after already setting it
    require(compareStrings(hand, "ROCK") || compareStrings(hand, "PAPER") || compareStrings(hand, "SCISSORS"));
    player1Hand = hand;
  }

  function setPlayer2Hand(string hand) public {

    require(msg.sender == player2);
    require(compareStrings(player2Hand, ""));         // cannot change hand after already setting it
    require(compareStrings(hand, "ROCK") || compareStrings(hand, "PAPER") || compareStrings(hand, "SCISSORS"));
    player2Hand = hand;
  }

  function revealHands() public {

    // either p1 or p2 can choose to reveal both hands
    require(msg.sender == player1 || msg.sender == player2);
    require(!(compareStrings(player1Hand, "")) && !(compareStrings(player2Hand, "")));          // but both hands must have been committed
    require(winner == -1);      // require winner not to already exist

    winner = outcomeMatrix[player1Hand][player2Hand];

    player1HandPublic = player1Hand;
    player2HandPublic = player2Hand;
  }

  function awardStakes() public {

    require(msg.sender == player1 || msg.sender == player2);
    require(winner != -1);    // require winner to have been determined by revealing of hands


    uint player1Winnings;
    uint player2Winnings;

    // send ether to appropriate players
    if (winner == 1) {

      // precalculate winnings to avoid re-entrancy vulnerability
      player1Winnings = initialStake + backingStake;
      initialStake = 0;
      backingStake = 0;
      player1.transfer(player1Winnings);

    } else if (winner == 2) {

      // precalculate winnings to avoid re-entrancy vulnerability
      player2Winnings = initialStake + backingStake;
      initialStake = 0;
      backingStake = 0;
      player2.transfer(player2Winnings);

    } else {

      // precalculate amount to avoid re-entrancy vulnerability
      player1Winnings = initialStake;
      player2Winnings = backingStake;
      initialStake = 0;
      backingStake = 0;
      player1.transfer(player1Winnings);
      player2.transfer(player2Winnings);

    }

    reset();

  }

  // if the game is taking too long or if no one is accepting the initial stake
  // then the contract owner can reset for other players to participate
  function gameTimeout() public {

    require(msg.sender == owner);
    require(now > initialisedTime + 24 * 3600 * 2);      // can only be called if current block is two days older than block when time was set

    // transfer deposits back to players

    // precalculate amount to avoid re-entrancy vulnerability
    uint player1Winnings = initialStake;
    initialStake = 0;
    player1.transfer(player1Winnings);


    if (backingStake != 0) {

      // precalculate amount to avoid re-entrancy vulnerability
      uint player2Winnings = backingStake;
      backingStake = 0;
      player2.transfer(player2Winnings);
    }

    reset();
  }

  // tear down all values, reset so game can be played again
  // cannot be called publicly, only once a game is over
  function reset() private {

    initialStake = 0;
    backingStake = 0;
    player1Hand = "";
    player2Hand = "";
    player1HandPublic = "";
    player2HandPublic = "";
    player1 = address(0);
    player2 = address(0);
    winner = -1;
  }

}
