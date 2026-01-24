const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("NFTCrosschain Extension", function () {
  let nft;
  let owner;
  let user;
  let operator;

  const getRequestId = async (tx) => {
    const receipt = await tx.wait();
    const event = receipt.logs
      .map((log) => {
        try {
          return nft.interface.parseLog(log);
        } catch {
          return null;
        }
      })
      .find((parsed) => parsed && parsed.name === "BridgeRequestCreated");

    return event.args.requestId;
  };

  beforeEach(async function () {
    [owner, user, operator] = await ethers.getSigners();
    const NFT = await ethers.getContractFactory("MockNFTCrosschain");
    nft = await NFT.deploy();
    await nft.waitForDeployment();

    await nft.setBridgeOperator(operator.address);
    await nft.setSupportedChain(137, true);
  });

  it("should create bridge request and lock token", async function () {
    await nft.mintToken(user.address, "uri1");

    const tx = await nft.connect(user).createBridgeRequest(0, 137);
    const requestId = await getRequestId(tx);
    const request = await nft.getBridgeRequest(requestId);

    expect(await nft.isTokenLocked(0)).to.equal(true);
    expect(request.destinationChainId).to.equal(137);
    expect(request.processed).to.equal(false);
  });

  it("should prevent creating requests for unsupported chains", async function () {
    await nft.mintToken(user.address, "uri1");

    await expect(nft.connect(user).createBridgeRequest(0, 999))
      .to.be.revertedWith("Chain not supported");
  });

  it("should allow operator to process bridge requests", async function () {
    await nft.mintToken(user.address, "uri1");
    const tx = await nft.connect(user).createBridgeRequest(0, 137);
    const requestId = await getRequestId(tx);

    await expect(nft.connect(operator).processBridgeRequest(requestId, true))
      .to.emit(nft, "BridgeRequestProcessed")
      .withArgs(requestId, true);

    const request = await nft.getBridgeRequest(requestId);
    expect(request.processed).to.equal(true);
    expect(await nft.isTokenLocked(0)).to.equal(true);
  });

  it("should unlock token on failed processing", async function () {
    await nft.mintToken(user.address, "uri1");
    const tx = await nft.connect(user).createBridgeRequest(0, 137);
    const requestId = await getRequestId(tx);

    await nft.connect(operator).processBridgeRequest(requestId, false);

    expect(await nft.isTokenLocked(0)).to.equal(false);
  });

  it("should block transfers when token is locked", async function () {
    await nft.mintToken(user.address, "uri1");
    await nft.connect(user).createBridgeRequest(0, 137);

    await expect(
      nft.connect(user).transferFrom(user.address, owner.address, 0)
    ).to.be.revertedWith("Token locked for bridging");
  });

  it("should reject processing by non-operator", async function () {
    await nft.mintToken(user.address, "uri1");
    const tx = await nft.connect(user).createBridgeRequest(0, 137);
    const requestId = await getRequestId(tx);

    await expect(nft.connect(user).processBridgeRequest(requestId, true))
      .to.be.revertedWith("Not bridge operator");
  });
});
