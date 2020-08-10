const etherlime = require("etherlime-lib");
const ethers = require("ethers");
const utils = ethers.utils;
const InterchangeExample = require("../build/InterchangeExample.json");
const InterchangeGroupSegment = require("../build/InterchangeGroupSegment.json");
const InterchangeSegment = require("../build/InterchangeSegment.json");
const Test1Segment = require("../build/Test1Segment.json");
const Test2Segment = require("../build/Test2Segment.json");

function getSelectors(contract) {
  let values = Array.from(new Set(Object.values(contract.interface.functions)));
  let selectors = values.reduce((acc, val) => {
    return acc + val.sighash.slice(2);
  }, "");
  return selectors;
}

describe("InterchangeExampleTest", () => {
  let aliceAccount = accounts[0];
  let deployer;
  let test1Segment;
  let test2Segment;
  let interchangeSegment;
  let interchangeGroupSegment;
  let interchangeExample;

  let result;
  let addresses;

  before(async () => {
    deployer = new etherlime.EtherlimeGanacheDeployer(aliceAccount.secretKey);
    interchangeExample = await deployer.deploy(InterchangeExample);
    test1Segment = await deployer.deploy(Test1Segment);
    test2Segment = await deployer.deploy(Test2Segment);

    //console.log(interchangeExample);
    interchangeGroupSegment = deployer.wrapDeployedContract(
      InterchangeGroupSegment,
      interchangeExample.contractAddress
    );
    interchangeSegment = deployer.wrapDeployedContract(
      InterchangeSegment,
      interchangeExample.contractAddress
    );
  });
  //function splitAddresses()

  it("should have three gsge", async () => {
    result = await interchangeGroupSegment.facetAddresses();
    addresses = result
      .slice(2)
      .match(/.{40}/g)
      .map((address) => utils.getAddress(address));
    assert.equal(addresses.length, 3);
  });

  it("GS/GE pairings should have the right function pairings (gsge", async () => {
    result = await interchangeGroupSegment.facetFunctionSelectors(addresses[0]);
    assert.equal(result, "0x99f5f52e");
    result = await interchangeGroupSegment.facetFunctionSelectors(addresses[1]);
    assert.equal(result, "0xadfca15e7a0ed627cdffacc652ef6b2c");
    result = await interchangeGroupSegment.facetFunctionSelectors(addresses[2]);
    assert.equal(result, "0x01ffc9a7");
  });

  it("Selectors should be associated to GS/GE pairings correctly", async () => {
    assert.equal(
      addresses[0],
      await interchangeGroupSegment.facetAddress("0x99f5f52e")
    );
    assert.equal(
      addresses[1],
      await interchangeGroupSegment.facetAddress("0xcdffacc6")
    );
    assert.equal(
      addresses[2],
      await interchangeGroupSegment.facetAddress("0x01ffc9a7")
    );
  });

  // There is an EDGE CASE where a company has multiple subsidaries and will use GS/GE pairings to delininate between different
  // subsidaries. The case comes in that companies could trading amongst themselves, cooking the books


  it("Should get all the GS/GE and function selectors of the contract", async () => {
    result = await interchangeGroupSegment.gsge();

    assert.equal(addresses[0], utils.getAddress(result[0].slice(0, 42)));
    assert.equal(result[0].slice(42), "99f5f52e");

    assert.equal(addresses[1], utils.getAddress(result[1].slice(0, 42)));
    assert.equal(result[1].slice(42), "adfca15e7a0ed627cdffacc652ef6b2c");

    assert.equal(addresses[2], utils.getAddress(result[2].slice(0, 42)));
    assert.equal(result[2].slice(42), "01ffc9a7");

    assert.equal(result.length, 3);
  });

  it("Should add test1 functions", async () => {
    let selectors = getSelectors(test1Segment);
    addresses.push(test1Segment.contractAddress);
    result = await interchangeSegment.interchangeSet([
      test1Segment.contractAddress + selectors,
    ]);
    result = await interchangeGroupSegment.facetFunctionSelectors(addresses[3]);
    let frontSelector = selectors.slice(-8);
    selectors = "0x" + frontSelector + selectors.slice(0, -8);
    assert.equal(result, selectors);
  });

  it("should add test2 functions", async () => {
    let selectors = getSelectors(test2Segment);
    addresses.push(test2Segment.contractAddress);
    result = await interchangeSegment.interchangeSet([
      test2Segment.contractAddress + selectors,
    ]);
    result = await interchangeGroupSegment.facetFunctionSelectors(addresses[4]);
    assert.equal(result, "0x" + selectors);
  });

  it("should remove some test2 functions", async () => {
    let selectors = getSelectors(test2Segment);
    removeSelectors =
      selectors.slice(0, 8) + selectors.slice(32, 48) + selectors.slice(-16);
    result = await interchangeSegment.interchangeSet([
      ethers.constants.AddressZero + removeSelectors,
    ]);
    result = await interchangeGroupSegment.facetFunctionSelectors(addresses[4]);
    selectors =
      selectors.slice(-40, -32) +
      selectors.slice(8, 32) +
      selectors.slice(-32, -16) +
      selectors.slice(48, -40);
    assert.equal(result, "0x" + selectors);
  });

  it("should remove some test1 functions", async () => {
    let selectors = getSelectors(test1Segment);
    let frontSelector = selectors.slice(-8);
    selectors = frontSelector + selectors.slice(0, -8);

    removeSelectors = selectors.slice(8, 16) + selectors.slice(64, 80);
    result = await interchangeSegment.interchangeSet([
      ethers.constants.AddressZero + removeSelectors,
    ]);
    result = await interchangeGroupSegment.facetFunctionSelectors(addresses[3]);
    selectors =
      selectors.slice(0, 8) + selectors.slice(16, 64) + selectors.slice(80);
    assert.equal(result, "0x" + selectors);
  });
});
