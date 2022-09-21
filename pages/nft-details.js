import { useState, useEffect, useContext } from 'react';
import Image from 'next/image';
import { useRouter } from 'next/router';

import { NFTContext } from '../context/NFTContext';
import { Loader, NFTCard, Button } from '../components';
import images from '../assets';

import { shortenAddress } from '../utils/shortenAddress';

const NFTDetails = () => {
  const { currentAccount } = useContext(NFTContext);
  const [isLoading, setIsLoading] = useState(true);
  const router = useRouter();

  return (
    <div className="relative flex justify-center md:flex-col min-h-screen">
      <div className="relative flex-1 flexCenter sm:px-4 p-12 border-r md:border-r-0 md:border-b dark:border-nft-black-1 border-nft-gray-1">
        <div className="">
          <Image src={nft.image} />

        </div>

      </div>
    </div>

  );
};

export default NFTDetails;
