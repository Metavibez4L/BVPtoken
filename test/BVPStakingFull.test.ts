import { expect } from "chai";
import { ethers } from "hardhat";
import { time } from "@nomicfoundation/hardhat-network-helpers";
import type { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import type { BVPToken, BVPStaking } from "../typechain-types";

describe("BVPStaking Full Suite", function () {
  let owner: SignerWithAddress;
  let user: SignerWithAddress;
  let token: BVPToken;
  let staking: BVPStaking;

  // Lock constant must match your contract
  const LOCK_3M = 90 * 24 * 3600;

  beforeEach(async function () {
    [owner, user] = await ethers.getSigners();

    // Deploy token (5% treasury to owner, 95% to deployer)
    const TF = await ethers.getContractFactory("BVPToken");
    token = (await TF.deploy(owner.address)) as BVPToken;
    await token.waitForDeployment();

    // Fund user
    await token.transfer(user.address, ethers.parseEther("1000000"));

    // Deploy staking
    const SF = await ethers.getContractFactory("BVPStaking");
    staking = (await SF.deploy(await token.getAddress())) as BVPStaking;
    await staking.waitForDeployment();

    // Approve
    await token.connect(user).approve(await staking.getAddress(), ethers.MaxUint256);
  });

  it("lets user stake3Months, prevents double-stake, then unlock & unstake", async function () {
    const amt = ethers.parseEther("50000");
    // initial balances
    expect(await token.balanceOf(user.address)).to.equal(ethers.parseEther("1000000"));

    // stake
    await expect(staking.connect(user).stake3Months(amt))
      .to.emit(staking, "Staked")
      .withArgs(user.address, amt, LOCK_3M, await time.latest() + LOCK_3M);

    // double-stake should revert
    await expect(staking.connect(user).stake3Months(amt))
      .to.be.revertedWith("Already staked");

    // cannot unlock early
    await expect(staking.connect(user).unlock())
      .to.be.revertedWith("Stake still locked");

    // advance time past lock
    await time.increase(LOCK_3M + 1);

    // unlock
    await expect(staking.connect(user).unlock())
      .to.emit(staking, "Unlocked")
      .withArgs(user.address, await time.latest());

    // unstake
    await expect(staking.connect(user).unstake())
      .to.emit(staking, "Unstaked")
      .withArgs(user.address, amt);

    // user got tokens back
    expect(await token.balanceOf(user.address))
      .to.equal(ethers.parseEther("1000000"));
  });

  it("owner can emergencyWithdraw even before unlock", async function () {
    const amt = ethers.parseEther("12345");
    await staking.connect(user).stake3Months(amt);

    // user balance decreased
    expect(await token.balanceOf(user.address)).to.equal(ethers.parseEther("1000000").sub(amt));

    // non-owner cannot emergencyWithdraw
    await expect(staking.connect(user).emergencyWithdraw(user.address))
      .to.be.revertedWith("Ownable: caller is not the owner");

    // owner emergencyWithdraw
    await expect(staking.connect(owner).emergencyWithdraw(user.address))
      .to.emit(staking, "Unstaked")
      .withArgs(user.address, amt);

    // user recovers full
    expect(await token.balanceOf(user.address))
      .to.equal(ethers.parseEther("1000000"));
  });

  // Tier thresholds from contract
  const tiers = [
    { amt: "0",         code: 0, name: "None"      },
    { amt: "20000",     code: 1, name: "Bronze"    },
    { amt: "100000",    code: 2, name: "Silver"    },
    { amt: "500000",    code: 3, name: "Gold"      },
    { amt: "1000000",   code: 4, name: "Platinum"  },
    { amt: "2000000",   code: 5, name: "Diamond"   },
  ];

  tiers.forEach(t => {
    it(`assigns tier ${t.name} for staking ${t.amt}`, async function () {
      const amount = ethers.parseUnits(t.amt, 18);
      if (amount.gt(0)) {
        await staking.connect(user).stake3Months(amount);
      }
      expect(await staking.getTierCode(user.address)).to.equal(t.code);
      expect(await staking.getTierName(user.address)).to.equal(t.name);

      // cleanup stakes for next case
      if (amount.gt(0)) {
        // fast-forward and unlock+unstake to reset
        await time.increase(LOCK_3M + 1);
        await staking.connect(user).unlock();
        await staking.connect(user).unstake();
      }
    });
  });
});
