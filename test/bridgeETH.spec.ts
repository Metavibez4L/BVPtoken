import { expect } from "chai";
import { ethers } from "hardhat";

describe("Bridge ETH to L2BVPReceiver (local test)", function () {
  let deployer: any;
  let mockInbox: any;
  let l1ETHGateway: any;
  let l2BVPReceiver: any;

  const BVP_TOKEN = "0x6450A13E72f0999dC86A419af219C79738172318"; // Replace with mock if needed

  beforeEach(async function () {
    [deployer] = await ethers.getSigners();

    // Deploy mock L2 receiver
    const Receiver = await ethers.getContractFactory("L2BVPReceiver");
    l2BVPReceiver = await Receiver.deploy(BVP_TOKEN, deployer.address);
    await l2BVPReceiver.deployed();

    // Deploy mock Arbitrum Inbox
    const Inbox = await ethers.getContractFactory("MockInbox");
    mockInbox = await Inbox.deploy();
    await mockInbox.deployed();

    // Deploy L1ETHGateway with mockInbox
    const Gateway = await ethers.getContractFactory("L1ETHGateway");
    l1ETHGateway = await Gateway.deploy(mockInbox.address, l2BVPReceiver.address);
    await l1ETHGateway.deployed();
  });

  it("should emit RetryableTicketCreated (no revert)", async function () {
    const tx = await l1ETHGateway.bridgeETH(
      ethers.utils.parseUnits("0.001", "ether"), // maxSubmissionCost
      500_000, // gasLimit
      ethers.utils.parseUnits("1", "gwei"), // maxFeePerGas
      { value: ethers.utils.parseUnits("0.01", "ether") }
    );

    const receipt = await tx.wait();
    expect(receipt.status).to.equal(1);

    const log = receipt.logs.find((log) =>
      log.topics[0] === ethers.utils.id("RetryableTicketCreated(address,bytes)")
    );
    expect(log).to.not.be.undefined;
    console.log("✅ Local bridge test passed.");
  });
});
