pragma solidity ^0.4.24

contract RPS {

  string[] public permittedHands;
  mapping (string => mapping(string => uint256)) public outcomeMatrix;

  uint256 public initialStake;    // cannot be negative
  uint256 public backingStake;
  address player1;
  address player2;
  string player1Hand;
  string player2Hand;
  int winner;


  constructor() public {

    permittedHands.push("ROCK");
    permittedHands.push("PAPER");
    permittedHands.push("SCISSORS");

    outcomeMatrix["ROCK"]["ROCK"] = 0;
    outcomeMatrix["ROCK"]["PAPER"] = 2;
    outcomeMatrix["ROCK"]["SCISSORS"] = 1;
    outcomeMatrix["PAPER"]["ROCK"] = 1;
    outcomeMatrix["PAPER"]["PAPER"] = 0;
    outcomeMatrix["PAPER"]["SCISSORS"] = 2;
    outcomeMatrix["SCISSORS"]["ROCK"] = 2;
    outcomeMatrix["SCISSORS"]["PAPER"] = 1;
    outcomeMatrix["SCISSORS"]["SCISSORS"] = 0;

    initialStake = 0;
    backingStake = 0;
    player1Hand = "";
    player2Hand = "";
    winner = -1;

  }

  function initialiseStake() payable public {
    require(initialStake == 0);
    initialStake = msg.value;
    player1 = msg.sender;

  }

  function acceptStake() payable public {
    require(initialStake != 0 && msg.value == initialStake && backingStake == 0);   // cant be called twice
    player2 = msg.sender;
    backingStake = msg.value;
  }


  function setPlayer1Hand(string hand) public {
    require(msg.sender == player1);
    require(player1Hand == "");         // cant change hand after other was set
    require(hand == permittedHands[0] || hand == permittedHands[1] || hand == permittedHands[2]);
    player1Hand = hand;
  }

  function setPlayer2Hand(string hand) public {
    require(msg.sender == player2);
    require(player2Hand == "");
    require(hand == permittedHands[0] || hand == permittedHands[1] || hand == permittedHands[2]);
    player2Hand = hand;
  }

  function revealHands() public returns mapping(string => string) {
    require(player1Hand != "" && player2Hand != "");
    require(winner == -1);
    mapping handsCommitted(string => string);
    handsCommitted["player1"] = player1Hand;
    handsCommitted["player2"] = player2Hand;
    winner = outcomeMatrix[player1Hand][player2Hand];

    return handsCommitted;
  }

  function awardStakes() public {
    require(winner != -1);

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

  function reset() {
    initialStake = 0;
    backingStake = 0;
    player1Hand = "";
    player2Hand = "";
    winner = -1;
  }

}
