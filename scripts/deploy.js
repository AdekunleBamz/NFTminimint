async function main() {
  const [deployer] = await ethers.getSigners();
  const NFTminimint = await ethers.getContractFactory("NFTminimint");
  const nftminimint = await NFTminimint.deploy();

  await nftminimint.deployed();

  console.log("Deployer:", deployer.address);
  console.log("NFTminimint deployed to:", nftminimint.address);
  console.log("mintFee:", (await nftminimint.mintFee()).toString());
  console.log("maxSupply:", (await nftminimint.maxSupply()).toString());
  console.log("maxPerWallet:", (await nftminimint.maxPerWallet()).toString());
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
