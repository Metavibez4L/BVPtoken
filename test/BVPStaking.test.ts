import { ethers } from "hardhat";
import { expect } from "chai";
import { Contract } from "ethers";

describe("BVPStaking", function () {
  let bvpToken: Contract;
  let staking: Contract;
  let owner: any;
  let user: any;

  beforeEach(async () => {
    [owner, user] = await ethers.getSigners();

    const Token = await ethers.getContractFactory("BVPToken");
    bvpToken = await Token.deploy(
      owner.address, owner.address, owner.address, owner.address,
      owner.address, owner.address, owner.address, owner.address,
      owner.address
    );
    await bvpToken.deployed();

    const Staking = await ethers.getContractFactory("BVPStaking");
    staking = await Staking.deploy(bvpToken.address);
    await staking.deployed();

    await bvpToken.transfer(user.address, ethers.utils.parseEther("1000000"));
    await bvpToken.connect(user).approve(staking.address, ethers.utils.parseEther("1000000"));
  });

  it("should stake and assign Silver tier", async () => {
    await staking.connect(user).stake3Months(ethers.utils.parseEther("100000"));
    const [amount,, lockTime,, unlockAt] = await staking.getStake(user.address);
    expect(amount.toString()).to.equal(ethers.utils.parseEther("100000").toString());
    expect(lockTime.toString()).to.equal((90 * 24 * 60 * 60).toString());

    const tier = await staking.getTierName(user.address);
    expect(tier).to.equal("Silver");
  });

  it("should unlock and unstake after lock time", async () => {
    await staking.connect(user).stake3Months(ethers.utils.parseEther("100000"));

    // fast-forward time by 91 days
    await ethers.provider.send("evm_increaseTime", [91 * 24 * 60 * 60]);
    await ethers.provider.send("evm_mine", []);

    await staking.connect(user).unlock();
    await staking.connect(user).unstake();

    const [amount] = await staking.getStake(user.address);
    expect(amount.toString()).to.equal("0");
  });
});
