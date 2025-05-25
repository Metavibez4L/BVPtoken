import { ethers } from "hardhat";
import { expect } from "chai";
import { Contract } from "ethers";

describe("BVPStaking", function () {
  let token: Contract;
  let staking: Contract;
  let recipients: any[];

  beforeEach(async () => {
    recipients = await ethers.getSigners();

    token = await (await ethers.getContractFactory("BVPToken")).deploy(
      recipients[0].address, // Public Sale
      recipients[1].address, // Operations
      recipients[2].address, // Presale
      recipients[3].address, // Founders & Team
      recipients[4].address, // Marketing
      recipients[5].address, // Advisors
      recipients[6].address, // Treasury
      recipients[7].address  // Liquidity
    );
    await token.deployed();

    staking = await (await ethers.getContractFactory("BVPStaking")).deploy(token.address);
    await staking.deployed();

    await token.connect(recipients[0]).transfer(recipients[8].address, ethers.utils.parseEther("100000"));
    await token.connect(recipients[8]).approve(staking.address, ethers.utils.parseEther("100000"));
  });

  it("should stake and assign Silver tier", async () => {
    await staking.connect(recipients[8]).stake3Months(ethers.utils.parseEther("100000"));
    const stake = await staking.getStake(recipients[8].address);

    expect(stake.amount.toString()).to.equal(ethers.utils.parseEther("100000").toString());
    const tier = await staking.getTierName(recipients[8].address);
    expect(tier).to.equal("Silver");
  });
});
