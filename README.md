# X12 Interchange Standard

>  i.e. an X12Interchange object through solidity, then to a raw X12 interchange and returnable as a **valid X12 stream.**

This is an implementation of the `interchangeSet` function form [X12](https://x12.org) and the Interchange Group functions from the X12  Electronic Data Interchange Standard.

> Note: You must have a commerical developers license to use this in production, or you mat transact through our deployments in which we have a commerical license for usage.

The `interchangeSet` implementation avoids data storage read and writes. Fits 8 function selectors in a single data storage slot. 

The `contracts/InterchangeExample.sol` file shows an example of implementing X12 4010 850 EDI Data Interchange

The `test/interchangeExampleTest.js` file gives tests for the `interchangeSet` function and the Interchange Group functions.

The Implementaiton is the boilerplate code you need for a X12 Interchange Contract.

> The [InterchangeSegment.sol](./#) and [InterchangeGroupSegment.sol](./#) contracts implement the `interchangeSet` function and the TA1 (i.e. Acknowledgement) functions.

The [InterchangeExample.sol](./#)  This contract is the Interchange Proxy. It enables upgradability in the event of contract mishap.

The [InterchangeStorageContract.sol](./#) shows how to implement Interchange Transaction Data Storage. This contract includes contract ownership which can be updated should your `Trading Channel` conclude (e.g. you no longer do business with your counterparty).

## Interchange Functions

In order to call a function that exists in an addressable  Interchange you need to use the ABI information of the segment that has the function.

This infromation is provided in the `TradingChannel` typically. Open ABI Information for "Open Trading Channels" are a phase 2 implementation. [See Roadmap](https://github.com/freight-trust/protocol)

Here is an example that uses web3.js:

```javascript
let GSGTPairingSegment = new web3.eth.Contract(
  GSGTPairingSegment.abi,
  interchangeAddress
);
```

In the code above we create a contract variable so we can call contract functions with it.

In this example we know we will use a interchange because we pass a interchange's address as the second argument. But we are using an ABI from the `GSGTPairingSegment` segment so we can call functions that are defined in that segment. `GSGTPairingSegment`'s functions must have been added to the interchange (using interchangeSet) in order for the interchange to use the function information provided by the ABI of course.

Similarly you need to use the ABI of a segment in Solidity code in order to call functions from a interchange. Here's an example of Solidity code that calls a function from a interchange:

```solidity
string result = GSGTPairingSegment(interchangeAddress).getResult()
```

## Security

## Contact

## License

MIT license for Solidity Code Only
X12.org retains all copyright and rights to the X12 EDI Transaction Set under the Commerical License
