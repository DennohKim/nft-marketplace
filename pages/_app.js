import Script from 'next/script';
import { ThemeProvider } from 'next-themes';
// import { CeloProvider } from '@celo/react-celo';
import { Navbar, Footer } from '../components';
// import '@celo/react-celo/lib/styles.css';

import { NFTProvider } from '../context/NFTContext';
import '../styles/globals.css';

const MyApp = ({ Component, pageProps }) => (

  <NFTProvider>
    <ThemeProvider attribute="class">

      <div className=" dark:bg-nft-dark bg-white min-h-screen ">
        <Navbar />
        <div className="pt-65">

          <Component {...pageProps} />

        </div>
        <Footer />

      </div>
      <Script src="https://kit.fontawesome.com/6749fd5a79.js" crossOrigin="anonymous" />
    </ThemeProvider>
  </NFTProvider>

);

export default MyApp;
