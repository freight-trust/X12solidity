/**SPDX-License-identifer:  MIT*/
pragma solidity >=0.6.4 <0.7.0;
pragma experimental ABIEncoderV2;

import "./InterchangeStorageContract.sol";
import "./InterchangeHeaders.sol";
import "./InterchangeSegment.sol";
import "./InterchangeGroupSegment.sol";

contract InterchangeExample is InterchangeStorageContract {

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    
    constructor() public {
        InterchangeStorage storage ds = interchangeStorage();
        ds.contractOwner = msg.sender;        
        emit OwnershipTransferred(address(0), msg.sender);

        // Create a InterchangeSegment contract which implements the Interchange interface
        InterchangeSegment interchangeSegment = new InterchangeSegment();

        // Create a InterchangeGroupSegment contract which implements the Interchange Group interface
        InterchangeGroupSegment interchangeGroupSegment = new InterchangeGroupSegment();   

        bytes[] memory interchangeSet = new bytes[](3);

        // Adding cut function
        interchangeSet[0] = abi.encodePacked(interchangeSegment, Interchange.interchangeSet.selector);

        // Adding interchange sgement pairs functions                
        interchangeSet[1] = abi.encodePacked(
            interchangeGroupSegment,
            InterchangeGroup.facetFunctionSelectors.selector,
            InterchangeGroup.gsge.selector,
            InterchangeGroup.facetAddress.selector,
            InterchangeGroup.facetAddresses.selector            
        );    

        // Adding supportsInterface function
        interchangeSet[2] = abi.encodePacked(address(this), ERC165.supportsInterface.selector);

        // execute cut function
        bytes memory TA1 = abi.encodeWithSelector(Interchange.interchangeSet.selector, interchangeSet);
        (bool success,) = address(interchangeSegment).delegatecall(TA1);
        require(success, "Adding functions failed.");        

        // adding ERC165 data
        ds.supportedInterfaces[ERC165.supportsInterface.selector] = true;
        ds.supportedInterfaces[Interchange.interchangeSet.selector] = true;
        bytes4 interfaceID = InterchangeGroup.gsge.selector ^ InterchangeGroup.facetFunctionSelectors.selector ^ InterchangeGroup.facetAddresses.selector ^ InterchangeGroup.facetAddress.selector;
        ds.supportedInterfaces[interfaceID] = true;
    }

    // This is an immutable functions because it is defined directly in the interchange.
    // This implements ERC-165.
    function supportsInterface(bytes4 _interfaceID) external view returns (bool) {
        InterchangeStorage storage ds = interchangeStorage();
        return ds.supportedInterfaces[_interfaceID];
    }

    // Finds segment for function that is called and executes the
    // function if it is found and returns any value.
    fallback() external payable {
        InterchangeStorage storage ds = interchangeStorage();
        address segment = address(bytes20(ds.gsge[msg.sig]));
        require(segment != address(0), "Function does not exist.");
        assembly {
            let ptr := mload(0x40)
            calldatacopy(ptr, 0, calldatasize())
            let result := delegatecall(gas(), segment, ptr, calldatasize(), 0, 0)
            let size := returndatasize()
            returndatacopy(ptr, 0, size)
            switch result
            case 0 {revert(ptr, size)}
            default {return (ptr, size)}
        }
    }

    receive() external payable {
    }
}
  