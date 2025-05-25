import { ethers } from "hardhat";
import { expect } from "chai";
import { Contract } from "ethers";

describe("BVPToken", function () {
  let token: Contract;
  let recipients: any[];

  beforeEach(async () => {
    recipients = await ethers.getSigners();

    token = await (await ethers.getContractFactory("BVPToken")).deploy(
      recipients[0].address, // Public Sale
      recipients[1].address, // Operations
      recipients[2].address, // Presale
      recipients[3].address, // Founders & Team (10%)
      recipients[4].address, // Marketing
      recipients[5].address, // Advisors
      recipients[6].address, // Treasury
      recipients[7].address  // Liquidity
    );
    await token.deployed();
  });

  it("should have correct total supply", async () => {
    const totalSupply = await token.totalSupply();
    const expected = ethers.utils.parseEther("1000000000");
    expect(totalSupply.toString()).to.equal(expected.toString());
  });

  it("should distribute correct allocations", async () => {
    const checkAlloc = async (index: number, expectedPercent: number) => {
      const bal = await token.balanceOf(recipients[index].address);
      const expected = ethers.utils.parseEther((1000000000 * expectedPercent / 100).toString());
      expect(bal.toString()).to.equal(expected.toString());
    };

    await checkAlloc(0, 30); // Public Sale
    await checkAlloc(1, 20); // Operations
    await checkAlloc(2, 10); // Presale
    await checkAlloc(3, 10); // Founders & Team
    await checkAlloc(4, 15); // Marketing
    await checkAlloc(5, 5);  // Advisors
    await checkAlloc(6, 5);  // Treasury
    await checkAlloc(7, 5);  // Liquidity
  });

  it("should allow transfers", async () => {
    await token.connect(recipients[0]).transfer(recipients[8].address, ethers.utils.parseEther("100"));
    const bal = await token.balanceOf(recipients[8].address);
    expect(bal.toString()).to.equal(ethers.utils.parseEther("100").toString());
  });
});
