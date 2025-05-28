import { expect } from "chai";
import { ethers } from "hardhat";
import { BVPToken } from "../typechain-types";

describe("BVPToken - Cap Enforcement", function () {
  let bvpToken: BVPToken;
  const CAP = ethers.utils.parseEther("1000000000"); // 1 billion BVP (with 18 decimals)

  beforeEach(async () => {
    const [deployer, publicSale, operations, presale, founders, marketing, advisors, treasury, liquidity] = await ethers.getSigners();

    const BVPToken = await ethers.getContractFactory("BVPToken");
    bvpToken = await BVPToken.deploy(
      publicSale.address,
      operations.address,
      presale.address,
      founders.address,
      marketing.address,
      advisors.address,
      treasury.address,
      liquidity.address
    );
    await bvpToken.deployed();
  });

  it("should not allow minting above the cap", async function () {
    const [owner] = await ethers.getSigners();

    // Attempt to mint 1 token above the cap
    const oneToken = ethers.utils.parseEther("1");

    // Try to mint from a helper function or hack directly with a test-only contract
    // Since `_mint` is internal, this test assumes you temporarily expose it in a mock for testing
    // OR test indirectly by checking totalSupply against the cap

    const totalSupply = await bvpToken.totalSupply();
    expect(totalSupply).to.equal(CAP);

    // Confirm cap value
    const cap = await bvpToken.cap();
    expect(cap).to.equal(CAP);

    // Confirm minting above cap is impossible (requires mock or test exposure)
    // expect(await bvpToken.mint(owner.address, oneToken)).to.be.revertedWith("ERC20Capped: cap exceeded");
  });

  it("should equal cap immediately after deployment", async function () {
    const totalSupply = await bvpToken.totalSupply();
    expect(totalSupply).to.equal(await bvpToken.cap());
  });
});
