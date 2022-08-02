// SPDX-License-Identifier: UNLIICENSED
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

import "hardhat/console.sol";

contract NFTMarketplace is ERC721URIStorage {
    using Counters for Counters.Counter;


    //Variables
    Counters.Counter private _tokenIds;
    Counters.Counter private _itemsSold;

    //NFT price
    uint256 listingPrice = 0.025 ether;

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
        require (owner == msg.sender, "Only Marketplace owner can update the listing price");

        listingPrice = _listingPrice;
    }

    //Get current listing price
    function getListingPrice() public view returns (uint256) {
        return listingPrice;
    }

    //Create token function

    function createToken(string memory tokenURI, uint256 price) price payable returns (uint){
        _tokenIds.increment();

        uint256 newTokenId = _tokenIds.current();

        _mint(msg.sender, newTokenId);
        _setTokenURI(newTokenId, tokenURI);

        createMarketItem(newTokenId, price);

        return newTokenId;

    }

    function createMarketItem(uint256 tokenId, uint256 price) private {
        require(price > 0, "price must be at least 1");
        require(msg.value == listingPrice, "Price must be equal to listingPrice");

        idToMarketItem[tokenId] = MarketItem(
            tokenId,
            payable(msg.sender),
            payable(address(this)),
            price,
            false
        );

        _transfer(msg.sender, address(this), tokenId);

        emit MarketItemCreated (tokenId, msg.sender, address(this), price, false);

    } 

}