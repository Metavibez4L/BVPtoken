import { expect } from "chai";
import { ethers } from "hardhat";
import { Contract, parseEther } from "ethers";

describe("BVPToken", function () {
  let token: Contract;
  let publicSale: any,
      operations: any,
      presale: any,
      founders: any,
      marketing: any,
      advisors: any,
      treasury: any,
      liquidity: any,
      user: any;

  beforeEach(async () => {
    const signers = await ethers.getSigners();
    [
      publicSale,
      operations,
      presale,
      founders,
      marketing,
      advisors,
      treasury,
      liquidity,
      user
    ] = signers;

    const TokenF = await ethers.getContractFactory("BVPToken");
    token = await TokenF.deploy(
      publicSale.address,
      operations.address,
      presale.address,
      founders.address,
      marketing.address,
      advisors.address,
      treasury.address,
      liquidity.address
    );
    await token.waitForDeployment(); // ✅ v6
  });

  it("should have correct total supply", async () => {
    const total = await token.totalSupply();
    const cap = await token.cap();
    expect(total).to.equal(cap);
  });

  it("should distribute correct allocations", async () => {
    const balances = await Promise.all([
      token.balanceOf(publicSale.address),
      token.balanceOf(operations.address),
      token.balanceOf(presale.address),
      token.balanceOf(founders.address),
      token.balanceOf(marketing.address),
      token.balanceOf(advisors.address),
      token.balanceOf(treasury.address),
      token.balanceOf(liquidity.address),
    ]);

    // each allocation should be non-zero
    balances.forEach((b, i) => expect(b, `alloc[${i}]`).to.be.gt(0n));

    // sum equals total supply
    const sum = balances.reduce((a, b) => a + b, 0n);
    const total = await token.totalSupply();
    expect(sum).to.equal(total);
  });

  it("should allow transfers", async () => {
    // transfer from publicSale to user
    const amount = parseEther("1000");
    await token.connect(publicSale).transfer(user.address, amount);

    const userBal = await token.balanceOf(user.address);
    expect(userBal).to.equal(amount);
  });
});
