// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract GamePowerUps is ERC1155, ERC1155Burnable, Ownable, ReentrancyGuard {
  using Counters for Counters.Counter;
  using SafeMath for uint256;
  Counters.Counter public powerCount; //total count of powerups

  //struct of powerUp
  struct powerUpInfo {
    uint256 tokenId;
    uint256 price;
    string uri;
  }

  IERC20 token; //the token address

  //mapping of tokenId to the struct of powerUp
  mapping(uint256 => powerUpInfo) public powerUps;
  //mapping of tokenId to a bool to check weather the id exists or not
  mapping(uint256 => bool) public exists;

  uint256[] public tokenIds; // array of powerup ids/token ids
  string private baseURI;

  //constructor requires a token address
  constructor(IERC20 _token, string memory _baseURI) ERC1155(_baseURI) {
    token = _token;
    baseURI = _baseURI;
  }

  //Events
  event Added(uint256 indexed tokenId, uint256 price, string uri);

  event Withdraw(address indexed to, address indexed from, uint256 amount);

  event Bought(
    address indexed to,
    address indexed from,
    uint256 indexed tokenId,
    uint256 quantity,
    uint256 cost
  );

  event Used(address indexed from, uint256 indexed tokenId, uint256 quantity);

  event Removed(uint256 indexed tokenId);

  event UpdatedPrice(uint256 indexed tokenId, uint256 price);

  event UpdatedUri(uint256 indexed tokenId, string uri);

  event BaseUri(string uri);

  //Modifiers
  //modifier to check that the tokenId doesn't exist
  modifier notExisting(uint256 tokenId) {
    require(!exists[tokenId], "The PowerUp Exists.");
    _;
  }
  //modifier to check that the tokenId exist
  modifier existing(uint256 tokenId) {
    require(exists[tokenId], "The PowerUp doesn't Exist.");
    _;
  }
  modifier tokenPrice(uint256 price) {
    require(price > 0, "Price must be greater than 0.");
    _;
  }
  modifier tokenQuantity(uint256 quantity) {
    require(quantity > 0, "Quantity must be greater than 0.");
    _;
  }

  //Functions
  //function to add a powerUp
  function addPowerUp(
    uint256 tokenId,
    uint256 price,
    string memory _uri
  ) external onlyOwner notExisting(tokenId) tokenPrice(price) {
    powerUps[tokenId] = powerUpInfo(tokenId, price, _uri);
    exists[tokenId] = true;
    tokenIds.push(tokenId);
    powerCount.increment();
    emit Added(tokenId, price, _uri);
  }

  //function to buy a powerUp
  function buyPowerUp(
    uint256 tokenId,
    uint256 quantity
  ) external existing(tokenId) tokenQuantity(quantity) nonReentrant {
    powerUpInfo storage power = powerUps[tokenId];
    uint256 cost = power.price.mul(quantity);
    require(
      token.balanceOf(msg.sender) >= cost,
      "Insufficient funds to buy powerUp."
    );

    token.transferFrom(msg.sender, address(this), cost);
    _mint(msg.sender, tokenId, quantity, "");
    emit Bought(msg.sender, address(this), tokenId, quantity, cost);
  }

  //function to remove a powerUp
  function removePowerUp(uint256 tokenId) external onlyOwner existing(tokenId) {
    for (uint256 i = 0; i < tokenIds.length; i++) {
      if (tokenIds[i] == tokenId) {
        tokenIds[i] = tokenIds[tokenIds.length - 1];
        tokenIds.pop();
        exists[tokenId] = false;
        delete powerUps[tokenId];
        powerCount.decrement();
      }
    }
    emit Removed(tokenId);
  }

  //function to use a powerUp
  function usePowerUp(
    uint256 tokenId,
    uint256 quantity
  ) external existing(tokenId) tokenQuantity(quantity) {
    require(
      balanceOf(msg.sender, tokenId) >= quantity,
      "You don't have enough powerups."
    );
    _burn(msg.sender, tokenId, quantity);
    emit Used(msg.sender, tokenId, quantity);
  }

  //function to update the powerUp price
  function updatePowerUpPrice(
    uint256 tokenId,
    uint256 price
  ) external onlyOwner existing(tokenId) tokenPrice(price) {
    powerUps[tokenId].price = price;
    emit UpdatedPrice(tokenId, price);
  }

  //function to update the uri of the powerUp
  function updatePowerUpUri(
    uint256 tokenId,
    string memory _uri
  ) external onlyOwner existing(tokenId) {
    powerUps[tokenId].uri = _uri;
    emit UpdatedUri(tokenId, _uri);
  }

  //function to set or update the baseUri
  function setBaseURI(string memory newBaseURI) external onlyOwner {
    _setURI(newBaseURI);
    baseURI = newBaseURI;
    emit BaseUri(newBaseURI);
  }

  //function to withdraw funds from this contract and transfer it to the owner address
  function withdraw() external onlyOwner nonReentrant {
    uint256 amount = token.balanceOf(address(this));
    require(amount > 0, "The current balance of the contract is 0");
    token.transfer(msg.sender, amount);
    emit Withdraw(msg.sender, address(this), amount);
  }

  //function to get all powerUps
  function getPowerUps() external view returns (powerUpInfo[] memory) {
    powerUpInfo[] memory n = new powerUpInfo[](powerCount.current());
    for (uint256 i = 0; i < powerCount.current(); i++) {
      powerUpInfo memory pwr = powerUpInfo(
        powerUps[tokenIds[i]].tokenId,
        powerUps[tokenIds[i]].price,
        uri(powerUps[tokenIds[i]].tokenId)
      );
      n[i] = pwr;
    }
    return n;
  }

  //function to get the baseUri
  function getBaseURI() public view virtual returns (string memory) {
    return baseURI;
  }

  //function to get uri of token
  function uri(
    uint256 tokenId
  ) public view virtual override existing(tokenId) returns (string memory) {
    return string(abi.encodePacked(baseURI, powerUps[tokenId].uri));
  }
}
