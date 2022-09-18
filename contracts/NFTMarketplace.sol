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

    constructor(){
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

    //Create market item
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

    //Resell NFT function
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



}