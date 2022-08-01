import { Banner } from '../components';

const Home = () => (
  <div className="flex justify-center sm:px-4 p-12 ">
    <div className="w-full minwd:w-4/5">
      <Banner />
    </div>
    <h1 className="text-3xl font-bold underline">Hello World!</h1>
  </div>
);

export default Home;
