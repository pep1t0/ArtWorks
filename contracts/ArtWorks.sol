// SPDX-License-Identifier: MIT
// Version mejorada
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract ArtToken is ERC721, Ownable {

    // Smart Contract constructor 
    constructor(string memory _name, string memory _symbol) 
    ERC721(_name, _symbol) Ownable(msg.sender) {}

    // NFT Token counter
    uint256 COUNTER;

    // Pricing of NFT 
    uint256 fee = 5 ether;

    // Data structure 
    struct Art {
        string name;
        uint256 tokenId;
        uint256 dna;      
        uint8 level;
        uint8 rarity;
        // string description;
        // uint256 price;
    }

    // Storage structure 
    Art [] public art_works;

    // Declaration of an event
    event NewArtWork (address indexed owner, uint256 id, uint256 dna);

    // Funciones auxiliares

    function _createRandomNum(uint256 _mod) internal view returns (uint256) {
        bytes32 hash_randomNum = keccak256(abi.encodePacked(block.timestamp, msg.sender));
        uint256 randonNum = uint256(hash_randomNum) % _mod;
        return randonNum;
    }

    mapping(uint256 => uint256) public tokenPrices;

    function setTokenPrice(uint256 _tokenId, uint256 _price) public {
        require(_price > 0, "Price must be greater than zero");

        // Verifica si el token existe. Si el token no existe, `ownerOf` lanzará un error.
        address tokenOwner = ownerOf(_tokenId);
        require(tokenOwner != address(0), "Token does not exist");
        require(tokenOwner == msg.sender, "You are not the owner of this token");
        
        // En caso de que el token ya exista, se actualiza su precio
        tokenPrices[_tokenId] = _price * 10**18;
    }


    function createArtWork(string memory _name, uint256 _price) public onlyOwner {
        uint8 randRarity = uint8(_createRandomNum(1000));
        uint256 randDna = _createRandomNum(10**16);

        Art memory newArtWork = Art(_name, COUNTER, randDna, 1, randRarity);
        art_works.push(newArtWork);
        _safeMint(msg.sender, COUNTER);

        setTokenPrice(COUNTER, _price);
        
        emit NewArtWork(msg.sender, COUNTER, randDna);
        COUNTER++;
    }
 
    function buyArtWork(uint256 _tokenId) public payable {
        uint256 price = tokenPrices[_tokenId];
        require(price > 0, "Token not for sale");
        require(msg.value >= price, "Not enough funds");

        address _owner = ownerOf(_tokenId);
        _transfer(_owner, msg.sender, _tokenId);

        // Transfer the payment to the contract owner
        address payable contractOwner = payable(owner());

        contractOwner.transfer(msg.value);

        // Clear the token price
        tokenPrices[_tokenId] = 0;
    }


    function updateFee(uint256 _fee) external onlyOwner {
        fee = _fee;
    }

    function infoSmartContract() public view returns (address, uint256) {
        address SC_address = address(this);
        uint256 SC_money = address(this).balance / 10**18;
        return (SC_address, SC_money);
    }

    function getArtWorks() public view returns (Art [] memory) {
        return art_works;
    }

    function getOwnerArtWork(address _owner) public view returns (Art [] memory) {
        Art [] memory result = new Art[](balanceOf(_owner));
        uint256 counter_owner = 0;

        for(uint256 i = 0; i < art_works.length; i++) {            
            if(ownerOf(i) == _owner) {
                result[counter_owner] = art_works[i];
                counter_owner++;
            }
        }
        return result;
    } 

    // NFT Token payment
    //function createRandomArtWork(string memory _name) public payable {
    //    require(msg.value >= fee, "Not enough funds");
    //     _createArtWork(_name);
    //}

    // Extraccion de ethers del Smart Contract a mi dirección (wallet)
    function withdraw() external payable onlyOwner {
        address payable _owner = payable(owner());
        _owner.transfer(address(this).balance); // Cantidad total de ethers en el SC

    }

    function levelUp(uint256 _artId) public {
        require(ownerOf(_artId) == msg.sender);
        art_works[_artId].level++;
    }
  
}
