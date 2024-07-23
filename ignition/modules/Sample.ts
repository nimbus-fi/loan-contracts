import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

const SampleModule = buildModule("IdentityPass Module", (m) => {
  const sample = m.contract("IdentityPassNFT");
  return { sample };
});

export default SampleModule;
