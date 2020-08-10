/**SPDX-License-identifer:  MIT*/

pragma solidity >=0.6.4 <0.7.0;
pragma experimental ABIEncoderV2;

import "./InterchangeStorageContract.sol";
import "./InterchangeHeaders.sol";

contract InterchangeGroupSegment is InterchangeGroup, InterchangeStorageContract {
    /// These functions are expected to be called frequently
    /// by tools. Therefore the return values are tightly
    /// packed for efficiency. That means no padding with zeros.    
    
    struct Segment {
        address segment;
        bytes4[] functionSelectors;
    }  

    /// @notice Gets all gsge and their selectors.
    /// @return An array of bytes arrays containing each segment 
    ///         and each segment's selectors.
    /// The return value is tightly packed.
    /// That means no padding with zeros.
    /// Here is the structure of the return value:
    /// returnValue = [
    ///     abi.encodePacked(segment, sel1, sel2, sel3, ...),
    ///     abi.encodePacked(segment, sel1, sel2, sel3, ...),
    ///     ...
    /// ]    
    /// segment is the address of a  transaction segment.    
    // a transaction segment is NOT a transaction SET
    // a FULL transaction SET would be something like the `X12INTERCHANGE.sol` file 
    // Segments make up Transaction SETS. Mulitple different Transaction Sets from different 
    // Businessess can make up a TRANSACTION SET. as we are using the X12 Transaction Segmeent Definitions
    /// sel1, sel2, sel3 etc. are four-byte function selectors.
    function gsge() external view override returns(bytes[] memory) {
        InterchangeStorage storage ds = interchangeStorage();
        uint totalSelectorSlots = ds.selectorTransactionSet;
        uint selectorSlotLength = uint128(totalSelectorSlots >> 128);
        totalSelectorSlots = uint128(totalSelectorSlots);        
        uint totalSelectors = totalSelectorSlots * 8 + selectorSlotLength;
        if(selectorSlotLength > 0) {
            totalSelectorSlots++;
        }
        
        // get default size of arrays
        uint defaultSize = totalSelectors;        
        if(defaultSize > 20) {
            defaultSize = 20;
        }        
        Segment[] memory facets_ = new Segment[](defaultSize);
        uint8[] memory numSegmentSelectors = new uint8[](defaultSize);
        uint numSegments;
        uint selectorCount;
        // loop through function selectors
        for(uint slotIndex; selectorCount < totalSelectors; slotIndex++) {            
            bytes32 slot = ds.selectorSlots[slotIndex];
            for(uint selectorIndex; selectorIndex < 8; selectorIndex++) {
                selectorCount++;
                if(selectorCount > totalSelectors) {
                    break;
                }
                bytes4 selector = bytes4(slot << selectorIndex * 32);
                address segment = address(bytes20(ds.gsge[selector]));
                bool continueLoop = false;                
                for(uint facetIndex; facetIndex < numSegments; facetIndex++) {
                    if(facets_[facetIndex].segment == segment) {                    
                        uint arrayLength = facets_[facetIndex].functionSelectors.length;
                        // if array is too small then enlarge it
                        if(numSegmentSelectors[facetIndex]+1 > arrayLength) {
                            bytes4[] memory biggerArray = new bytes4[](arrayLength + defaultSize);
                            // copy contents of old array
                            for(uint i; i < arrayLength; i++) {
                                biggerArray[i] = facets_[facetIndex].functionSelectors[i];
                            }
                            facets_[facetIndex].functionSelectors = biggerArray;
                        }
                        facets_[facetIndex].functionSelectors[numSegmentSelectors[facetIndex]] = selector;
                        // probably will never have more than 255 functions from one segment contract
                        require(numSegmentSelectors[facetIndex] < 255);
                        numSegmentSelectors[facetIndex]++;
                        continueLoop = true;
                        break;
                    }    
                }
                if(continueLoop) {
                    continueLoop = false;
                    continue;
                }
                uint arrayLength = facets_.length;
                // if array is too small then enlarge it
                if(numSegments+1 > arrayLength) {
                    Segment[] memory biggerArray = new Segment[](arrayLength + defaultSize);
                    uint8[] memory biggerArray2 = new uint8[](arrayLength + defaultSize);
                    for(uint i; i < arrayLength; i++) {
                        biggerArray[i] = facets_[i];
                        biggerArray2[i] = numSegmentSelectors[i];        
                    }
                    facets_ = biggerArray;
                    numSegmentSelectors = biggerArray2;        
                }
                facets_[numSegments].segment = segment;
                facets_[numSegments].functionSelectors = new bytes4[](defaultSize);
                facets_[numSegments].functionSelectors[0] = selector;            
                numSegmentSelectors[numSegments] = 1;
                numSegments++;
            }
        }
        bytes[] memory returnSegments = new bytes[](numSegments);
        for(uint facetIndex; facetIndex < numSegments; facetIndex++) {
            uint numSelectors = numSegmentSelectors[facetIndex];
            bytes memory selectorsBytes = new bytes(4 * numSelectors);            
            bytes4[] memory selectors = facets_[facetIndex].functionSelectors;
            uint bytePosition;
            for(uint i; i < numSelectors; i++) {
                for(uint j; j < 4; j++) {
                    selectorsBytes[bytePosition] = byte(selectors[i] << j * 8);
                    bytePosition++;
                }
            }
            returnSegments[facetIndex] = abi.encodePacked(facets_[facetIndex].segment, selectorsBytes);
        }
        return returnSegments;
    }
   
    /// @notice Gets all the function selectors supported by a specific segment.
    /// @param _facet The segment address.
    /// @return A bytes array of function selectors.
    /// The return value is tightly packed. Here is an example:
    /// return abi.encodePacked(selector1, selector2, selector3, ...)
    function facetFunctionSelectors(address _facet) external view override returns(bytes memory) {
        InterchangeStorage storage ds = interchangeStorage();
        uint totalSelectorSlots = ds.selectorTransactionSet;
        uint selectorSlotLength = uint128(totalSelectorSlots >> 128);
        totalSelectorSlots = uint128(totalSelectorSlots);        
        uint totalSelectors = totalSelectorSlots * 8 + selectorSlotLength;
        if(selectorSlotLength > 0) {
            totalSelectorSlots++;
        }                       

        uint numSegmentSelectors;        
        bytes4[] memory facetSelectors = new bytes4[](totalSelectors);
        uint selectorCount;
        // loop through function selectors
        for(uint slotIndex; selectorCount < totalSelectors; slotIndex++) {
            bytes32 slot = ds.selectorSlots[slotIndex];
            for(uint selectorIndex; selectorIndex < 8; selectorIndex++) {
                selectorCount++;
                if(selectorCount > totalSelectors) {
                    break;
                }
                bytes4 selector = bytes4(slot << selectorIndex * 32);
                address segment = address(bytes20(ds.gsge[selector]));
                if(_facet == segment) {
                    facetSelectors[numSegmentSelectors] = selector;          
                    numSegmentSelectors++;
                }
            }   
        }
        bytes memory returnBytes = new bytes(4 * numSegmentSelectors);
        uint bytePosition;
        for(uint i; i < numSegmentSelectors; i++) {
            for(uint j; j < 4; j++) {
                returnBytes[bytePosition] = byte(facetSelectors[i] << j * 8);
                bytePosition++;
            }
        }
        return returnBytes;
    }
    
    /// @notice Get all the segment addresses used by a interchange.
    /// @return A byte array of tightly packed segment addresses.
    /// Example return value: 
    /// return abi.encodePacked(facet1, facet2, facet3, ...)
    function facetAddresses() external view override returns(bytes memory) {
        InterchangeStorage storage ds = interchangeStorage();
        uint totalSelectorSlots = ds.selectorTransactionSet;
        uint selectorSlotLength = uint128(totalSelectorSlots >> 128);
        totalSelectorSlots = uint128(totalSelectorSlots);        
        uint totalSelectors = totalSelectorSlots * 8 + selectorSlotLength;
        if(selectorSlotLength > 0) {
            totalSelectorSlots++;
        }        
        address[] memory facets_ = new address[](totalSelectors);
        uint numSegments;
        uint selectorCount;
        // loop through function selectors
        for(uint slotIndex; selectorCount < totalSelectors; slotIndex++) {            
            bytes32 slot = ds.selectorSlots[slotIndex];
            for(uint selectorIndex; selectorIndex < 8; selectorIndex++) {
                selectorCount++;
                if(selectorCount > totalSelectors) {
                    break;
                }
                bytes4 selector = bytes4(slot << selectorIndex * 32);
                address segment = address(bytes20(ds.gsge[selector]));
                bool continueLoop = false;
                for(uint facetIndex; facetIndex < numSegments; facetIndex++) {
                    if(segment == facets_[facetIndex]) {
                        continueLoop = true;
                        break;
                    }
                }
                if(continueLoop) {
                    continueLoop = false;
                    continue;
                }
                facets_[numSegments] = segment;
                numSegments++;
            }
        }
        
        bytes memory returnBytes = new bytes(20 * numSegments);
        uint bytePosition;
        for(uint i; i < numSegments; i++) {
            for(uint j; j < 20; j++) {
                returnBytes[bytePosition] = byte(bytes20(facets_[i]) << j * 8);
                bytePosition++;
            }
        }
        return returnBytes;
    }

    /// @notice Gets the segment that supports the given selector.
    /// @dev If segment is not found return address(0).
    /// @param _functionSelector The function selector.
    /// @return The segment address.
    function facetAddress(bytes4 _functionSelector) external view override returns(address) {
        InterchangeStorage storage ds = interchangeStorage();
        return address(bytes20(ds.gsge[_functionSelector]));
    }
}