import { expect } from "chai";
import { ethers } from "hardhat";

describe("Bridge USDC to L2BVPReceiver (local test)", function () {
  let deployer: any;
  let usdc: any;
  let mockInbox: any;
  let gateway: any;
  let receiver: any;

  beforeEach(async () => {
    [deployer] = await ethers.getSigners();

    const MockERC20 = await ethers.getContractFactory("MockERC20");
    usdc = await MockERC20.deploy("Mock USDC", "USDC", 6);
    await usdc.deployed();
    await usdc.mint(deployer.address, ethers.utils.parseUnits("1000", 6));

    const Receiver = await ethers.getContractFactory("L2BVPReceiver");
    receiver = await Receiver.deploy(usdc.address, deployer.address);
    await receiver.deployed();

    const MockInbox = await ethers.getContractFactory("MockInbox");
    mockInbox = await MockInbox.deploy();
    await mockInbox.deployed();

    const Gateway = await ethers.getContractFactory("L1USDCGateway");
    gateway = await Gateway.deploy(usdc.address, mockInbox.address, receiver.address);
    await gateway.deployed();

    await usdc.approve(gateway.address, ethers.utils.parseUnits("100", 6));
  });

  it("should bridge USDC and emit correct RetryableTicketCreated calldata", async () => {
    const amount = ethers.utils.parseUnits("50", 6);

    const tx = await gateway.bridgeToBVP(
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
