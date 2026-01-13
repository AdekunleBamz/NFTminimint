async function main() {
  const NFTminimint = await ethers.getContractFactory("NFTminimint");
  const nftminimint = await NFTminimint.deploy();

  await nftminimint.deployed();

  console.log("NFTminimint deployed to:", nftminimint.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
