import { expect } from "chai";
import { ethers } from "hardhat";

describe("Sample", function () {
  let sample: any; // Use the appropriate type for your contract

  beforeEach(async () => {
    // Deploy the Sample contract before each test
    const Sample = await ethers.getContractFactory("Sample");
    sample = await Sample.deploy();
  });

  it("getName returns a string", async function () {
    // Assuming the Sample contract has a getName function that returns a string
    const name = await sample.getName();
    expect(name).to.be.a("string");
  });

  it("can change name", async function () {
    // Assuming the Sample contract has a setName function
    const newName = "Hardhat";
    await sample.setName(newName);
    expect(await sample.getName()).to.equal(newName);
  });
});
