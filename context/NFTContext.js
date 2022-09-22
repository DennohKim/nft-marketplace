import React, { useState, useEffect } from 'react';
import Web3Modal from 'web3modal';
import { ethers } from 'ethers';
import axios from 'axios';
import { create as ipfsHttpClient } from 'ipfs-http-client';

import { MarketAddress, MarketAddressABI } from './constants';

// Connect to infura gateway

const projectId = process.env.NEXT_PUBLIC_IPFS_PROJECT_ID;
const projectSecret = process.env.NEXT_PUBLIC_IPFS_PROJECT_SECRET;
const auth = `Basic ${Buffer.from(`${projectId}:${projectSecret}`).toString(
  'base64',
)}`;
const options = {
  host: 'ipfs.infura.io',
  protocol: 'https',
  port: 5001,
  headers: { authorization: auth },
};
const client = ipfsHttpClient(options);
const dedicatedEndPoint = process.env.NEXT_PUBLIC_IPFS_DEDICATED_ENDPOINT;

// ----------------------------------------------------------------------------------------

// Function to create contract when the seller or creator is passed in
const fetchContract = (signerOrProvider) => new ethers.Contract(MarketAddress, MarketAddressABI, signerOrProvider);

// Create NFT Context
export const NFTContext = React.createContext();
export const NFTProvider = ({ children }) => {
  const [currentAccount, setCurrentAccount] = useState('');

  const nftCurrency = 'ETH';

  // Check if connected function

  const checkIfWalletIsConnected = async () => {
    if (!window.ethereum) return alert('Please install Metamask');

    const accounts = await window.ethereum.request({ method: 'eth_accounts' });
    if (accounts.length) {
      setCurrentAccount(accounts[0]);
    } else {
      console.log('No accounts found');
    }
  };

  useEffect(() => {
    checkIfWalletIsConnected();
  }, []);

  // Connect wallet function
  const connectWallet = async () => {
    if (!window.ethereum) return alert('Please install Metamask');
    const accounts = await window.ethereum.request({
      method: 'eth_requestAccounts',
    });

    setCurrentAccount(accounts[0]);

    window.location.reload();
  };

  // Upload image to IPFS

  const uploadToIPFS = async (file) => {
    try {
      const added = await client.add({ content: file });

      const url = `${dedicatedEndPoint}/ipfs/${added.path}`;

      return url;
    } catch (error) {
      console.log('Error uploading file to IPFS: ', error);
    }
  };

  // Function to list new NFT
  const createSale = async (url, formInputPrice) => {
    // setting up the contract
    const web3Modal = new Web3Modal();
    const connection = await web3Modal.connect();
    const provider = new ethers.providers.Web3Provider(connection);

    // Person making the contract
    const signer = provider.getSigner();

    // convert amount to blockchain readable format i.e wei or gwei
    const price = ethers.utils.parseUnits(formInputPrice, 'ether');
    const contract = fetchContract(signer);
    const listingPrice = await contract.getListingPrice();

    const transaction = await contract.createToken(url, price, { value: listingPrice.toString() });
    await transaction.wait();
  };

  // crete NFT function
  const createNFT = async (formInput, fileUrl, router) => {
    const { name, description, price } = formInput;

    if (!name || !description || !price || !fileUrl) return;

    const data = JSON.stringify({ name, description, image: fileUrl });

    try {
      const added = await client.add(data);

      const url = `${dedicatedEndPoint}/ipfs/${added.path}`;

      await createSale(url, price);

      router.push('/');
    } catch (error) {
      console.log('Error uploading file to IPFS.');
    }
  };

  const fetchNFTs = async () => {
    const provider = new ethers.providers.JsonRpcProvider();
    const contract = fetchContract(provider);

    // Getting array of promises containing our NFT data
    const data = await contract.fetchMarketItems();

    // Fetch all NFT's simultaneously
    const items = await Promise.all(data.map(async ({ tokenId, seller, owner, price: unformattedPrice }) => {
      const tokenURI = await contract.tokenURI(tokenId);
      const { data: { image, name, description } } = await axios.get(tokenURI);
      const price = ethers.utils.formatUnits(unformattedPrice.toString(), 'ether');

      return {
        price,
        tokenId: tokenId.toNumber(),
        seller,
        owner,
        image,
        name,
        description,
        tokenURI,
      };
    }));

    return items;
  };

  // Fetch only listedNfTs

  const fetchMyNFTsOrListedNfTs = async (type) => {
    // setting up the contract
    const web3Modal = new Web3Modal();
    const connection = await web3Modal.connect();
    const provider = new ethers.providers.Web3Provider(connection);

    // Person making the contract
    const signer = provider.getSigner();

    const contract = fetchContract(signer);

    const data = type === 'fetchItemsListed'
      ? await contract.fetchItemsListed()
      : await contract.fetchMyNFTs();

    // Fetch all NFT's simultaneously
    const items = await Promise.all(data.map(async ({ tokenId, seller, owner, price: unformattedPrice }) => {
      const tokenURI = await contract.tokenURI(tokenId);
      const { data: { image, name, description } } = await axios.get(tokenURI);
      const price = ethers.utils.formatUnits(unformattedPrice.toString(), 'ether');

      return {
        price,
        tokenId: tokenId.toNumber(),
        seller,
        owner,
        image,
        name,
        description,
        tokenURI,
      };
    }));
    return items;
  };

  // BuyNFT function

  const buyNFT = async (nft) => {
    // setting up the contract
    const web3Modal = new Web3Modal();
    const connection = await web3Modal.connect();
    const provider = new ethers.providers.Web3Provider(connection);

    // Person making the contract
    const signer = provider.getSigner();

    const contract = fetchContract(signer);

    // Format NFT price
    const price = ethers.utils.parseUnits(nft.price.toString(), 'ether');

    // Make transaction
    const transaction = await contract.createMarketSale(nft.tokenId, { value: price });

    await transaction.wait();
  };

  return (
    <NFTContext.Provider
      value={{ nftCurrency, connectWallet, currentAccount, uploadToIPFS, createNFT, fetchNFTs, fetchMyNFTsOrListedNfTs, buyNFT }}
    >
      {children}
    </NFTContext.Provider>
  );
};
