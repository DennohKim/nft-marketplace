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
        address payable seller;
        address payable owner;
        uint256 price;
        bool sold;
    }

//Event to trigger once market item is created
    event MarketItemCreated (
        uint256 indexed tokenId,
        address seller,
        address owner,
        uint256 price,
        bool sold

    );

    constructor() ERC721("Metaverse Tokens", "METT"){
        //Owner of the contract is the one that is deploying it.
        owner = payable(msg.sender);
    }

    //Function to update the listing price
    function updateListingPrice(uint _listingPrice) public payable {
        //Making sure we are the owner 
        require (owner == msg.sender, "Only Marketplace owner can update the listing price");

        listingPrice = _listingPrice;
    }

    //Get current listing price
    function getListingPrice() public view returns (uint256) {
        return listingPrice;
    }

    //Create token function

    function createToken(string memory tokenURI, uint256 price) public payable returns (uint){
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
    function createMarketItem(uint256 tokenId, uint256 price) private {
        require(price > 0, "price must be at least 1");
        require(msg.value == listingPrice, "Price must be equal to listingPrice");

        //Create mapping for market items
        idToMarketItem[tokenId] = MarketItem(
            tokenId,
            payable(msg.sender),
            payable(address(this)), //Address of sender
            price,
            false
        );

        _transfer(msg.sender, address(this), tokenId); //transfer ownership of NFT

        emit MarketItemCreated (tokenId, msg.sender, address(this), price, false); 

    } 

    //Resell NFT 
    function resellToken(uint tokenId, uint256 price) public payable {
        //Check whether you can resell it
        require (idToMarketItem[tokenId].owner == msg.sender, "Only item owner can perform this function");
        require(msg.value == listingPrice, "Price must be equal to selling price");

        idToMarketItem[tokenId].sold = false;
        idToMarketItem[tokenId].price = price;
        idToMarketItem[tokenId].seller = payable(msg.sender); //Person trying to resell the token
        idToMarketItem[tokenId].owner = payable(address(this)); //Belong to the NFT marketplace(smart contract). NOT any individual of the NFT marketplace
        
        _itemsSold.decrement();
        _transfer(msg.sender, address(this), tokenId);
    }

    //Create sale
    function createMarketSale(uint256 tokenId) public payable{
        uint price = idToMarketItem[tokenId].price;
        require(msg.value == price, "Please submit the asking price in order to complete the purchase");

        idToMarketItem[tokenId].owner = payable(msg.sender); //person buying item will be the owner
        idToMarketItem[tokenId].sold = true; //NFT has been sold
        idToMarketItem[tokenId].seller = payable(address(0)); //Seller was NFT marketplace - address 0 means it doesn't belong to any wallet

        _itemsSold.increment();
        _transfer(address(this), msg.sender, tokenId); //Transfer from NFT market place to the actual buyer
        payable(owner).transfer(listingPrice); //Transfer fee marketplace owner
        payable(idToMarketItem[tokenId].seller).transfer(msg.value); //transfer amount from buyer to seller

    }

   /* Returns all unsold market items */
    function fetchMarketItems() public view returns (MarketItem[] memory) {
      uint itemCount = _tokenIds.current();
      uint unsoldItemCount = _tokenIds.current() - _itemsSold.current();
      uint currentIndex = 0;

      // looping over the number of items created and increment that number if we have an empty address 

      // empty array called items
      // the type of the element in the array is marketitem, and the unsolditemcount is the lenght
      MarketItem[] memory items = new MarketItem[](unsoldItemCount);
      for (uint i = 0; i < itemCount; i++) {
        // check to see if the item is unsold -> checking if the owner is an empty address -> then it's unsold
        // above, where we were creating a new market item, we were setting the address to be an empty address
        // the address get's populated if the item is sold
        if (idToMarketItem[i + 1].owner == address(this)) {
          // the id of the item that we're currently interracting with
          uint currentId = i + 1;
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
        uint totalItemCount = _tokenIds.current();
        uint itemCount = 0;
        uint currentIndex = 0;

        for (uint i = 0; i < totalItemCount; i++){
            if(idToMarketItem[i + 1].owner == msg.sender){
                itemCount += 1;
            }

        }

        MarketItem[] memory items = new MarketItem[](itemCount);

          for (uint i = 0; i < totalItemCount; i++){
            if(idToMarketItem[i + 1].owner == msg.sender){
                uint currentId = i + 1;

                MarketItem storage currentItem = idToMarketItem[currentId];

                items[currentIndex] = currentItem;

                currentIndex += 1;
            }
        }

        return items;
    }

    function fetchItemsListed() public view returns (MarketItem[] memory){
        uint totalItemCount = _tokenIds.current();
        uint itemCount = 0;
        uint currentIndex = 0;

        for (uint i = 0; i < totalItemCount; i++){
            if(idToMarketItem[i + 1].seller == msg.sender){
                itemCount += 1;
            }

        }

        MarketItem[] memory items = new MarketItem[](itemCount);


          for (uint i = 0; i < totalItemCount; i++){
            if(idToMarketItem[i + 1].seller == msg.sender){
                uint currentId = i + 1;

                MarketItem storage currentItem = idToMarketItem[currentId];

                items[currentIndex] = currentItem;

                currentIndex += 1;
            }
        }

        return items;


    }
}