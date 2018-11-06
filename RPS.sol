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
    player1HandPublic = "";
    player2HandPublic = "";
    winner = -1;

  }


  // returns true of the passed strings are identical
  function compareStrings(string a, string b) private pure returns (bool) {
      return keccak256(abi.encodePacked(a)) == keccak256(abi.encodePacked(b));
  }

  // check to see if player 1 exists
  function player1Exists() public view returns (bool) {
      return (!(initialStake == 0));    // p1 would have set a deposit in order to play
  }

  // check to see if player 2 exists
  function player2Exists() public view returns (bool) {
      return (!(backingStake == 0));    // p2 would have set a deposit in order to play
  }

  // allows a player to set a deposit
  function initialiseStake() payable public {
    // require initial stake to be 0, can't already have been set
    require(initialStake == 0 && msg.value > 0);

    initialisedTime = now;        // block time of initialisation
    initialStake = msg.value;
    player1 = msg.sender;
  }

  // another player also deposits the same amount
  function acceptStake() payable public {
    // require a stake to be set previously before game can be accepted
    // require same amount of ether recieved here as initialStake
    // cannot be called twice in a row since backing stake is set
    require(initialStake != 0 && initialStake == msg.value && backingStake == 0);
    require(player1 != msg.sender);     // can't play against self

    player2 = msg.sender;
    backingStake = msg.value;
  }

  // player 1 sets which hand to play
  function setPlayer1Hand(string hand) public {
    // only player 1 can set his hand
    require(msg.sender == player1);
    require(compareStrings(player1Hand, ""));         // require hand to be currently empty, so cannot change hand after setting it
    require(compareStrings(hand, "ROCK") || compareStrings(hand, "PAPER") || compareStrings(hand, "SCISSORS"));   // hand must be one of these strings
    player1Hand = hand;
  }

  // check if p1 has set their hand
  function player1HandExists() view public returns (bool) {
      return (compareStrings(player1Hand, "ROCK") || compareStrings(player1Hand, "PAPER") || compareStrings(player1Hand, "SCISSORS"));
  }

  // player 2 sets which hand to play
  function setPlayer2Hand(string hand) public {
    // only player 2 can set his hand
    require(msg.sender == player2);
    require(compareStrings(player2Hand, ""));         // require hand to be currently empty, so cannot change hand after setting it
    require(compareStrings(hand, "ROCK") || compareStrings(hand, "PAPER") || compareStrings(hand, "SCISSORS"));   // hand must be one of these strings
    player2Hand = hand;
  }

  // check if p2 has set their hand
  function player2HandExists() view public returns (bool) {
      return (compareStrings(player2Hand, "ROCK") || compareStrings(player2Hand, "PAPER") || compareStrings(player2Hand, "SCISSORS"));
  }

  // either player can choose to reveal which hands were set to determine the winner
  function revealHands() public {
    // either p1 or p2 can choose to reveal both hands
    require(msg.sender == player1 || msg.sender == player2);
    require(player1HandExists() && player2HandExists());    // but both hands must have been set (cannot be empty strings)
    require(winner == -1);      // require winner to not already exist

    winner = outcomeMatrix[player1Hand][player2Hand];

    player1HandPublic = player1Hand;
    player2HandPublic = player2Hand;
  }

  // the deposits are sent to the respective player
  function awardStakes() public {

    require(msg.sender == player1 || msg.sender == player2);
    require(winner != -1);    // require winner to have been determined by the revealing of hands

    // variables to hold calculated winnings of the match
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

    // re-initialise game variables to allow a fresh match to begin
    reset();
  }

  // if the game is taking too long or if no one is accepting the initial stake
  // then the contract owner can reset for other players to participate
  function gameTimeout() public {

    require(msg.sender == owner);
    require(initialStake != 0);
    require(now > initialisedTime + 24 * 3600 * 2);      // can only be called if current block is two days older than block when time was set

    //// transfering deposits back to players ////

    // precalculate amount to avoid re-entrancy vulnerability
    uint player1Winnings = initialStake;
    initialStake = 0;
    player1.transfer(player1Winnings);

    // if player 2 had accepted stake, but no one is making any progress in the game
    if (backingStake != 0) {

      // precalculate amount to avoid re-entrancy vulnerability
      uint player2Winnings = backingStake;
      backingStake = 0;
      player2.transfer(player2Winnings);

    }

    // re-initialise game variables to allow a fresh match to begin
    reset();
  }

  // tear down all values, reset so game can be played again
  // cannot be called publicly, only once a game is over, or by contract owner under some constraints
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
    initialisedTime = 0;
  }

}
