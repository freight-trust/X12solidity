/**SPDX-License-identifer:  MIT*/
pragma solidity ^0.6.4;
pragma experimental ABIEncoderV2;

interface Interchange {
    /// @notice _interchangeSet is an array of bytes arrays.
    /// This argument is tightly packed for gas efficiency.
    /// That means no padding with zeros.
    /// Here is the structure of _interchangeSet:
    /// _interchangeSet = [
    ///     abi.encodePacked(segment, sel1, sel2, sel3, ...),
    ///     abi.encodePacked(segment, sel1, sel2, sel4, ...),
    ///     ...
    /// ]    
    /// segment is the address of a segment    
    /// sel1, sel2, sel3 etc. are four-byte function selectors.   
    function interchangeSet(bytes[] calldata _interchangeSet) external;
    event interchangeSet(bytes[] _interchangeSet);    
}


// A GS/GE segment pair  is a Functional Group of bounded interchanges (by the Pairing).
// These functions look at interchanges
interface InterchangeGroup {        
    /// These functions are expected to be called frequently
    /// by tools. Therefore the return values are tightly
    /// packed for efficiency. That means no padding with zeros.
    /// @notice Gets all gsge and their selectors.
    /// @return An array of bytes arrays containing each segment 
    ///         and each segment's selectors.
    /// The return value is tightly packed.
    /// Here is the structure of the return value:
    /// returnValue = [
    ///     abi.encodePacked(segment, sel1, sel2, sel3, ...),
    ///     abi.encodePacked(segment, sel1, sel2, sel3, ...),
    ///     ...
    /// ]    
    /// segment is the address of a segment.    
    /// sel1, sel2, sel3 etc. are four-byte function selectors.
    function gsge() external view returns(bytes[] memory);
    
    /// @notice Gets all the function selectors supported by a specific segment.
    /// @param _facet The segment address.
    /// @return A byte array of function selectors.
    /// The return value is tightly packed. Here is an example:
    /// return abi.encodePacked(selector1, selector2, selector3, ...)
    function facetFunctionSelectors(address _facet) external view returns(bytes memory);
    
    /// @notice Get all the segment addresses used by a interchange.
    /// @return A byte array of tightly packed segment addresses.
    /// Example return value: 
    /// return abi.encodePacked(facet1, facet2, facet3, ...)    
    function facetAddresses() external view returns(bytes memory);

    /// @notice Gets the segment that supports the given selector.
    /// @dev If segment is not found return address(0).
    /// @param _functionSelector The function selector.
    /// @return The segment address.
    function facetAddress(bytes4 _functionSelector) external view returns(address);    
}

interface ERC165 {
    /// @notice Query if a contract implements an interface
    /// @param interfaceID The interface identifier, as specified in ERC-165
    /// @dev Interface identification is specified in ERC-165. This function
    ///  uses less than 30,000 gas.
    /// @return `true` if the contract implements `interfaceID` and
    ///  `interfaceID` is not 0xffffffff, `false` otherwise
    function supportsInterface(bytes4 interfaceID) external view returns (bool);
}
