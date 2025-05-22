import { expect } from "chai";
import { ethers } from "hardhat";

describe("BVPStaking (non-upgradeable)", () => {
  let staking: Contract, token: Contract;
  let owner: SignerWithAddress, user: SignerWithAddress;

  beforeEach(async () => {
    [ owner, user ] = await ethers.getSigners();

    // deploy a minimal ERC20 for tests
    const ERC = await ethers.getContractFactory("ERC20Mock"); 
    token = await ERC.deploy("Test", "TST", owner.address, ethers.parseUnits("1000000", 18));
    await token.deployed();

    // now deploy staking with token.address
    const Factory = await ethers.getContractFactory("BVPStaking");
    staking = await Factory.deploy(token.address);
    await staking.deployed();

    // give user some tokens & approve
    await token.transfer(user.address, ethers.parseUnits("50000", 18));
    await token.connect(user).approve(staking.address, ethers.parseUnits("50000", 18));
  });

  it("lets user stake3Months, prevents double-stake, and only owner can emergencyWithdraw", async () => {
    // your test code here...
  });
});
