// SPDX-License-Identifier: UNLIICENSED
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

import "hardhat/console.sol";

//Inherit contract from ERC721URIstorage
contract NFTMarketplace is ERC721URIStorage {
    //Enable counter utility
    using Counters for Counters.Counter;


    //Variables
    Counters.Counter private _tokenIds; //private variable - cannot be called outside the NFTMarketplace class
    Counters.Counter private _itemsSold;

    //NFT price
    uint256 listingPrice = 0.025 ether; //Depending on network - change to celo

    //Owner of the contract
    address payable owner;

    //keeping up with new NFT's created
    mapping(uint256 => MarketItem) private idToMarketItem;

    
    struct MarketItem {
        uint256 tokenId;
        address payable owner;
        uint256 price;
        bool isForSale;
    }

//Event to trigger once market item is created
    event MarketItemCreated (
        uint256 indexed tokenId,
        address owner,
        uint256 price
    );

    constructor() ERC721("Metaverse Tokens", "METT"){
        //Owner of the contract is the one that is deploying it.
        owner = payable(msg.sender);
    }

    modifier onlyOwnerOfItem(uint256 _tokenId){
        require (idToMarketItem[_tokenId].owner == msg.sender, "Only item owner can perform this function");
        _;
    }

    modifier isCorrectValue(uint256 _value){
        require(msg.value == _value, "send correct value");
        _;
    }

    //Function to update the listing price
    function updateListingPrice(uint256 _listingPrice) public payable {
        //Making sure we are the owner 
        require (owner == msg.sender, "Only Marketplace owner can update the listing price");

        listingPrice = _listingPrice;
    }

    //Create token function

    function createToken(string memory tokenURI, uint256 price) public payable returns (uint256){
        require(price > 0, "price must be at least 1");
        //update token Id by one
        _tokenIds.increment();

        //Get current value of token Id
        uint256 newTokenId = _tokenIds.current();

        
        _mint(msg.sender, newTokenId); //Mint the token
        _setTokenURI(newTokenId, tokenURI); //Make token unique
        createMarketItem(newTokenId, price); //List it to market place

        return newTokenId;

    }

    //Put NFT to marketplace
    function createMarketItem(uint256 tokenId, uint256 price) private isCorrectValue(listingPrice){

        //Create mapping for market items
        idToMarketItem[tokenId] = MarketItem(
            tokenId,
            payable(msg.sender),
            price,
            false
        );

        _transfer(msg.sender, address(this), tokenId); //transfer ownership of NFT

        emit MarketItemCreated (tokenId, msg.sender, price); 

    } 
    


    //Resell NFT 
    function resellToken(uint256 tokenId, uint256 price) public payable isCorrectValue(listingPrice) onlyOwnerOfItem(tokenId){
        idToMarketItem[tokenId].isForSale = true;
        idToMarketItem[tokenId].price = price;
        
        _itemsSold.decrement();
        _transfer(msg.sender, address(this), tokenId);
    }

    //Create sale
    function createMarketSale(uint256 tokenId) public payable isCorrectValue(idToMarketItem[tokenId].price){
        require(idToMarketItem[tokenId].isForSale, "item not for sale");
        require(msg.sender != idToMarketItem[tokenId].owner, "can't buy your nft");

        address seller = idToMarketItem[tokenId].owner;
        idToMarketItem[tokenId].owner = payable(msg.sender); //person buying item will be the owner
        idToMarketItem[tokenId].isForSale = false; 

        _itemsSold.increment();
        
        _transfer(address(this), msg.sender, tokenId); //Transfer from NFT market place to the actual buyer
        payable(owner).transfer(listingPrice); //Transfer fee marketplace owner
        payable(seller).transfer(msg.value); //transfer amount from buyer to seller
    }

    //Withdraw sale
    function withdrawMarketSale(uint256 tokenId) public payable onlyOwnerOfItem(tokenId){
        idToMarketItem[tokenId].isForSale = false; 
        _transfer(address(this), msg.sender, tokenId); //Transfer from NFT market place to the seller
    }

   /* Returns all unsold market items */
    function fetchMarketItems() public view returns (MarketItem[] memory) {
      uint256 itemCount = _tokenIds.current();
      uint256 unsoldItemCount = _tokenIds.current() - _itemsSold.current();
      uint256 currentIndex = 0;

      // looping over the number of items created and increment that number if we have an empty address 

      // empty array called items
      // the type of the element in the array is marketitem, and the unsolditemcount is the lenght
      MarketItem[] memory items = new MarketItem[](unsoldItemCount);
      for (uint256 i = 0; i < itemCount; i++) {
        // check to see if the item is unsold -> checking if the owner is an empty address -> then it's unsold
        // above, where we were creating a new market item, we were setting the address to be an empty address
        // the address get's populated if the item is isForSale
        if (idToMarketItem[i + 1].owner == address(this)) {
          // the id of the item that we're currently interracting with
          uint256 currentId = i + 1;
          // get the mapping of the idtomarketitem with the -> gives us the reference to the marketitem
          MarketItem storage currentItem = idToMarketItem[currentId];
          // insert the market item to the items array
          items[currentIndex] = currentItem;
          // increment the current index
          currentIndex += 1;
        }
      }

      return items;
    }

    function fetchMyNFTs() public view returns (MarketItem[] memory) {
        uint256 totalItemCount = _tokenIds.current();
        uint256 itemCount = 0;
        uint256 currentIndex = 0;

        for (uint256 i = 0; i < totalItemCount; i++){
            if(idToMarketItem[i + 1].owner == msg.sender){
                itemCount += 1;
            }

        }

        MarketItem[] memory items = new MarketItem[](itemCount);

          for (uint256 i = 0; i < totalItemCount; i++){
            if(idToMarketItem[i + 1].owner == msg.sender){
                uint256 currentId = i + 1;

                MarketItem storage currentItem = idToMarketItem[currentId];

                items[currentIndex] = currentItem;

                currentIndex += 1;
            }
        }

        return items;
    }

    function fetchItemsListed() public view returns (MarketItem[] memory){
        uint256 totalItemCount = _tokenIds.current();
        uint256 itemCount = 0;
        uint256 currentIndex = 0;

        for (uint256 i = 0; i < totalItemCount; i++){
            if(idToMarketItem[i + 1].owner == msg.sender){
                itemCount += 1;
            }

        }

        MarketItem[] memory items = new MarketItem[](itemCount);


          for (uint256 i = 0; i < totalItemCount; i++){
            if(idToMarketItem[i + 1].owner == msg.sender){
                uint256 currentId = i + 1;

                MarketItem storage currentItem = idToMarketItem[currentId];

                items[currentIndex] = currentItem;

                currentIndex += 1;
            }
        }

        return items;
    }

    //Get current listing price
    function getListingPrice() public view returns (uint256) {
        return listingPrice;
    }
}