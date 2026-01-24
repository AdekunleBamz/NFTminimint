const { expect } = require("chai");
const { ethers } = require("hardhat");

function sortHex32(a, b) {
    return BigInt(a) <= BigInt(b) ? [a, b] : [b, a];
}

function hashPair(a, b) {
    const [left, right] = sortHex32(a, b);
    return ethers.keccak256(ethers.solidityPacked(["bytes32", "bytes32"], [left, right]));
}

function leafFor(address, allowance) {
    return ethers.keccak256(
        ethers.solidityPacked(["address", "uint256"], [address, allowance])
    );
}

function buildMerkleTree(leaves) {
    let level = leaves.slice();
    const layers = [level];

    while (level.length > 1) {
        const next = [];
        for (let i = 0; i < level.length; i += 2) {
            if (i + 1 === level.length) {
                next.push(level[i]);
            } else {
                next.push(hashPair(level[i], level[i + 1]));
            }
        }
        level = next;
        layers.push(level);
    }

    return { root: layers[layers.length - 1][0], layers };
}

function getProof(layers, leafIndex) {
    const proof = [];
    let index = leafIndex;

    for (let level = 0; level < layers.length - 1; level++) {
        const layer = layers[level];
        const isRightNode = index % 2 === 1;
        const pairIndex = isRightNode ? index - 1 : index + 1;

        if (pairIndex < layer.length) {
            proof.push(layer[pairIndex]);
        }

        index = Math.floor(index / 2);
    }

    return proof;
}

describe("NFTMerkleAllowance Extension", function () {
    let mock;
    let owner, alice, bob;

    beforeEach(async function () {
        [owner, alice, bob] = await ethers.getSigners();

        const MockNFTMerkleAllowance = await ethers.getContractFactory("MockNFTMerkleAllowance");
        mock = await MockNFTMerkleAllowance.deploy();
        await mock.waitForDeployment();
    });

    it("Should allow claiming up to allowance", async function () {
        const aliceAllowance = 2;
        const bobAllowance = 5;

        const leaves = [
            leafFor(alice.address, aliceAllowance),
            leafFor(bob.address, bobAllowance),
        ];

        const tree = buildMerkleTree(leaves);
        const aliceProof = getProof(tree.layers, 0);

        await mock.setMerkleRoot(tree.root);
        await mock.setEnabled(true);

        await expect(mock.connect(alice).claim(1, aliceAllowance, aliceProof))
            .to.not.be.reverted;

        expect(await mock.allowanceClaimed(alice.address)).to.equal(1);
        expect(await mock.totalMinted()).to.equal(1);

        await mock.connect(alice).claim(1, aliceAllowance, aliceProof);
        expect(await mock.allowanceClaimed(alice.address)).to.equal(2);

        await expect(mock.connect(alice).claim(1, aliceAllowance, aliceProof))
            .to.be.revertedWith("Allowance exceeded");
    });

    it("Should revert when disabled", async function () {
        const allowance = 1;
        const leaves = [leafFor(alice.address, allowance)];
        const tree = buildMerkleTree(leaves);
        const proof = getProof(tree.layers, 0);

        await mock.setMerkleRoot(tree.root);
        await mock.setEnabled(false);

        await expect(mock.connect(alice).claim(1, allowance, proof))
            .to.be.revertedWith("Allowance mint disabled");
    });

    it("Should reject invalid proofs / wrong allowance", async function () {
        const aliceAllowance = 2;
        const bobAllowance = 5;

        const leaves = [
            leafFor(alice.address, aliceAllowance),
            leafFor(bob.address, bobAllowance),
        ];

        const tree = buildMerkleTree(leaves);
        const aliceProof = getProof(tree.layers, 0);

        await mock.setMerkleRoot(tree.root);
        await mock.setEnabled(true);

        await expect(mock.connect(alice).claim(1, 999, aliceProof))
            .to.be.revertedWith("Invalid proof");

        await expect(mock.connect(bob).claim(1, bobAllowance, aliceProof))
            .to.be.revertedWith("Invalid proof");
    });
});
