import { expect } from "chai";
import { ethers } from "hardhat";
import type { BVPToken } from "../typechain-types";

describe("BVPToken allocation", function () {
  let token: BVPToken;
  let addrs: {
    publicSale: string;
    operations: string;
    presale: string;
    stakingRewards: string;
    marketing: string;
    founders: string;
    startTeam: string;
    advisors: string;
    treasury: string;
    liquidity: string;
  };

  beforeEach(async function () {
    const signers = await ethers.getSigners();
    addrs = {
      publicSale:     signers[1].address,
      operations:     signers[2].address,
      presale:        signers[3].address,
      stakingRewards: signers[4].address,
      marketing:      signers[5].address,
      founders:       signers[6].address,
      startTeam:      signers[7].address,
      advisors:       signers[8].address,
      treasury:       signers[9].address,
      liquidity:      signers[10].address,
    };

    const Factory = await ethers.getContractFactory("BVPToken");
    token = (await Factory.deploy(
      addrs.publicSale,
      addrs.operations,
      addrs.presale,
      addrs.stakingRewards,
      addrs.marketing,
      addrs.founders,
      addrs.startTeam,
      addrs.advisors,
      addrs.treasury,
      addrs.liquidity
    )) as BVPToken;
    await token.waitForDeployment();
  });

  it("has correct name & symbol", async function () {
    expect(await token.name()).to.equal("Big Vision Pictures Token");
    expect(await token.symbol()).to.equal("BVP");
  });

  it("mints exactly 1 000 000 000 tokens total", async function () {
    // totalSupply() returns a bigint
    const tot: bigint = await token.totalSupply();
    // expected = 1e9 * 1e18 = 1_000_000_000n * (10n ** 18n)
    const expected = 1_000_000_000n * (10n ** 18n);
    expect(tot).to.equal(expected);
  });

  it("allocates correct percentages to each address", async function () {
    const tot: bigint = await token.totalSupply();
    const pctOf = (p: number) => (tot * BigInt(p)) / 100n;

    expect(await token.balanceOf(addrs.publicSale)).to.equal(pctOf(30));
    expect(await token.balanceOf(addrs.operations)).to.equal(pctOf(20));
    expect(await token.balanceOf(addrs.presale)).to.equal(pctOf(10));
    expect(await token.balanceOf(addrs.stakingRewards)).to.equal(pctOf(10));
    expect(await token.balanceOf(addrs.marketing)).to.equal(pctOf(5));
    expect(await token.balanceOf(addrs.founders)).to.equal(pctOf(5));
    expect(await token.balanceOf(addrs.startTeam)).to.equal(pctOf(5));
    expect(await token.balanceOf(addrs.advisors)).to.equal(pctOf(5));
    expect(await token.balanceOf(addrs.treasury)).to.equal(pctOf(5));
    expect(await token.balanceOf(addrs.liquidity)).to.equal(pctOf(5));
  });
});
