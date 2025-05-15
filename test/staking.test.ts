import { ethers } from "hardhat";
import { expect } from "chai";

describe("BVP Token + Staking (No Tax)", function () {
  let token: any;
  let staking: any;
  let owner: any;
  let user: any;

  beforeEach(async () => {
    [owner, user] = await ethers.getSigners();

    const Token = await ethers.getContractFactory("BVPToken");
    token = await Token.deploy(owner.address); // Treasury arg now unused but still passed
    await token.waitForDeployment();

    const Staking = await ethers.getContractFactory("BVPStaking");
    staking = await Staking.deploy(await token.getAddress());
    await staking.waitForDeployment();

    await token.transfer(user.address, ethers.parseEther("2000000"));
    await token.connect(user).approve(await staking.getAddress(), ethers.parseEther("2000000"));
  });

  it("should stake, unlock after 90 days, and unstake", async () => {
    await staking.connect(user).stake(ethers.parseEther("10000"));
    await ethers.provider.send("evm_increaseTime", [91 * 86400]);
    await staking.connect(user).unlock();
    await staking.connect(user).unstake();

    const balance = await token.balanceOf(user.address);
    expect(balance).to.equal(ethers.parseEther("2000000"));
  });

  it("should return correct tier", async () => {
    await staking.connect(user).stake(ethers.parseEther("1500000"));
    const tier = await staking.getTier(user.address);
    expect(tier).to.equal("Platinum");
  });

  it("should allow emergency withdrawal by owner", async () => {
    await staking.connect(user).stake(ethers.parseEther("10000"));

    const before = await token.balanceOf(owner.address);
    await staking.emergencyWithdraw(user.address);
    const after = await token.balanceOf(owner.address);

    expect(after - before).to.equal(ethers.parseEther("10000"));
  });
});
