import { ethers } from "hardhat";
import { expect } from "chai";
import { Contract, parseEther } from "ethers";

describe("BVPStaking", function () {
  let token: Contract;
  let staking: Contract;
  let recipients: any[];

  beforeEach(async () => {
    recipients = await ethers.getSigners();

    const TokenF = await ethers.getContractFactory("BVPToken");
    token = await TokenF.deploy(
      recipients[0].address, // Public Sale
      recipients[1].address, // Operations
      recipients[2].address, // Presale
      recipients[3].address, // Founders & Team
      recipients[4].address, // Marketing
      recipients[5].address, // Advisors
      recipients[6].address, // Treasury
      recipients[7].address  // Liquidity
    );
    await token.waitForDeployment(); // ✅ v6

    const StakingF = await ethers.getContractFactory("BVPStaking");
    staking = await StakingF.deploy(await token.getAddress()); // or token.target
    await staking.waitForDeployment(); // ✅ v6

    // seed a user with tokens and approve staking
    await token.connect(recipients[0]).transfer(recipients[8].address, parseEther("100000"));
    await token.connect(recipients[8]).approve(await staking.getAddress(), parseEther("100000"));
  });

  it("should stake and assign Silver tier", async () => {
    await staking.connect(recipients[8]).stake3Months(parseEther("100000"));
    const stake = await staking.getStake(recipients[8].address);

    expect(stake.amount.toString()).to.equal(parseEther("100000").toString());
    const tier = await staking.getTierName(recipients[8].address);
    expect(tier).to.equal("Silver");
  });
});
