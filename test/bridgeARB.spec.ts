import { expect } from "chai";
import { ethers } from "hardhat";

describe("Bridge ARB to L2BVPReceiver (local test)", function () {
  let deployer: any;
  let arb: any;
  let mockInbox: any;
  let gateway: any;
  let receiver: any;

  beforeEach(async () => {
    [deployer] = await ethers.getSigners();

    const MockERC20 = await ethers.getContractFactory("MockERC20");
    arb = await MockERC20.deploy("Mock ARB", "ARB", 18);
    await arb.deployed();
    await arb.mint(deployer.address, ethers.utils.parseUnits("1000", 18));

    const Receiver = await ethers.getContractFactory("L2BVPReceiver");
    receiver = await Receiver.deploy(arb.address, deployer.address);
    await receiver.deployed();

    const MockInbox = await ethers.getContractFactory("MockInbox");
    mockInbox = await MockInbox.deploy();
    await mockInbox.deployed();

    const Gateway = await ethers.getContractFactory("L1ARBGateway");
    gateway = await Gateway.deploy(arb.address, mockInbox.address, receiver.address);
    await gateway.deployed();

    await arb.approve(gateway.address, ethers.utils.parseUnits("100", 18));
  });

  it("should bridge ARB and emit correct RetryableTicketCreated calldata", async () => {
    const amount = ethers.utils.parseUnits("50", 18);

    const tx = await gateway.bridgeARB(
      amount,
      ethers.utils.parseEther("0.001"),
      500_000,
      ethers.utils.parseUnits("1", "gwei"),
      { value: ethers.utils.parseEther("0.01") }
    );

    const receipt = await tx.wait();
    expect(receipt.status).to.equal(1);

    const log = receipt.logs.find((log) =>
      log.topics[0] === ethers.utils.id("RetryableTicketCreated(address,bytes)")
    );
    expect(log).to.not.be.undefined;

    const iface = new ethers.utils.Interface([
      "event RetryableTicketCreated(address to, bytes data)"
    ]);
    const parsed = iface.parseLog(log);
    const data = parsed.args.data;

    const calldataIface = new ethers.utils.Interface([
      "function releaseBVP(address,uint256)"
    ]);
    const decoded = calldataIface.decodeFunctionData("releaseBVP", data);

    expect(decoded[0]).to.equal(deployer.address);
    expect(decoded[1]).to.equal(amount);
  });
});
