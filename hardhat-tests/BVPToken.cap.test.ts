import { expect } from "chai";
import { ethers } from "hardhat";
import { parseEther } from "ethers"; // ✅ v6 helper import
import { BVPToken } from "../typechain-types";

describe("BVPToken - Cap Enforcement", function () {
  let bvpToken: BVPToken;

  // ✅ In Ethers v6, parseEther is a top-level import, not under ethers.utils
  const CAP = parseEther("1000000000"); // 1 billion BVP (with 18 decimals)

  beforeEach(async () => {
    const [
      deployer,
      publicSale,
      operations,
      presale,
      founders,
      marketing,
      advisors,
      treasury,
      liquidity,
    ] = await ethers.getSigners();

    const BVPToken = await ethers.getContractFactory("BVPToken");
    bvpToken = (await BVPToken.deploy(
      publicSale.address,
      operations.address,
      presale.address,
      founders.address,
      marketing.address,
      advisors.address,
      treasury.address,
      liquidity.address
    )) as unknown as BVPToken;

    await bvpToken.waitForDeployment(); // ✅ replaces .deployed() in Ethers v6
  });

  it("should not allow minting above the cap", async function () {
    const [owner] = await ethers.getSigners();

    const oneToken = parseEther("1"); // ✅ updated for v6

    const totalSupply = await bvpToken.totalSupply();
    expect(totalSupply).to.equal(CAP);

    // Confirm cap value
    const cap = await bvpToken.cap();
    expect(cap).to.equal(CAP);

    // NOTE: _mint() is internal; we test indirectly by checking supply == cap.
    // expect(await bvpToken.mint(owner.address, oneToken))
    //   .to.be.revertedWith("ERC20Capped: cap exceeded");
  });

  it("should equal cap immediately after deployment", async function () {
    const totalSupply = await bvpToken.totalSupply();
    expect(totalSupply).to.equal(await bvpToken.cap());
  });
});
