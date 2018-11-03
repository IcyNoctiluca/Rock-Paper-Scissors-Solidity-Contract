pragma solidity ^0.4.24

contract RPS {

  // to map combinations of hands to the winner
  mapping (string => mapping(string => uint256)) outcomeMatrix;

  uint256 public initialStake;    // cannot be negative
  uint256 backingStake;

  address player1;
  address player2;

  string player1Hand;
  string player2Hand;

  int winner;       // -1 initally, 0 for draw, 1 for player1, 2 for p2


  constructor() public {

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

  function initialiseStake() payable public {
    require(initialStake == 0 && msg.value > 0);
    initialStake = msg.value;
    player1 = msg.sender;
  }

  function acceptStake() payable public {
    // require an stake to be initialised before it can be accepted
    // require same amount of ether as init awardStakes
    // cannot be called twice in a row
    require(initialStake != 0 && initialStake == msg.value && backingStake == 0);

    player2 = msg.sender;
    backingStake = msg.value;
  }


  function setPlayer1Hand(string hand) public {
    require(msg.sender == player1);
    require(player1Hand == "");         // cannot change hand after already setting it
    require(hand == "ROCK" || hand == "PAPER" || hand == "SCISSORS");
    player1Hand = hand;
  }

  function setPlayer2Hand(string hand) public {
    require(msg.sender == player2);
    require(player2Hand == "");         // cannot change hand after already setting it
    require(hand == "ROCK" || hand == "PAPER" || hand == "SCISSORS");
    player2Hand = hand;
  }

  function revealHands() public returns mapping(string => string) {

    // either p1 or p2 can choose to reveal both hands
    require(msg.sender == player1 || msg.sender == player2);
    require(player1Hand != "" && player2Hand != "");          // but both hands must have been committed
    require(winner == -1);      // require winner not to already exist

    winner = outcomeMatrix[player1Hand][player2Hand];

    mapping (string => string) handsCommitted;
    handsCommitted["player1"] = player1Hand;
    handsCommitted["player2"] = player2Hand;

    return handsCommitted;
  }

  function awardStakes() public {

    require(msg.sender == player1 || msg.sender == player2);
    require(winner != -1);    // require winner to have been determined by revealing of hands

    // send ether to appropriate players
    if (winner == 1) {
      player1.transfer(initialStake + backingStake);
    } else if (winner == 2) {
      player2.transfer(initialStake + backingStake);
    } else {
      player1.transfer(initialStake);
      player2.transfer(backingStake);
    }

    reset();
  }

  // tear down all values, reset so game can be played again
  // cannot be called publicly, only once a game is over
  function reset() {
    initialStake = 0;
    backingStake = 0;
    player1Hand = "";
    player2Hand = "";
    player1 = address(0)
    player2 = address(0)
    winner = -1;
  }

}
