/** @type {import('next').NextConfig} */
const nextConfig = {
  reactStrictMode: true,
  swcMinify: true,
  images: {
    domains: ['chizaanfts.infura-ipfs.io', 'ipfs.infura.io'],
  },
  env: {
    BASE_URL: process.env.BASE_URL,
  },
  eslint: {
    ignoreDuringBuilds: true,
  },
};
module.exports = nextConfig;
