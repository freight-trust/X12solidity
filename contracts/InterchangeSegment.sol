/**SPDX-License-identifer:  MIT*/
pragma solidity >=0.6.4 <0.7.0;
pragma experimental ABIEncoderV2;

import "./InterchangeStorageContract.sol";
import "./InterchangeHeaders.sol";

contract InterchangeSegment is Interchange, InterchangeStorageContract {  
    bytes32 constant CLEAR_ADDRESS_MASK = 0x0000000000000000000000000000000000000000ffffffffffffffffffffffff;
    bytes32 constant CLEAR_SELECTOR_MASK = 0xffffffff00000000000000000000000000000000000000000000000000000000;

    struct SlotInfo {
        uint originalSelectorSlotsLength;                
        bytes32 selectorSlot;
        uint oldSelectorSlotsIndex;
        uint oldSelectorSlotIndex;
        bytes32 oldSelectorSlot;
        bool newSlot;
    }

    function interchangeSet(bytes[] memory _interchangeSet) public override {
        InterchangeStorage storage ds = interchangeStorage();      
        require(msg.sender == ds.contractOwner, "Must own the contract.");        
        SlotInfo memory slot;
        slot.originalSelectorSlotsLength = ds.selectorTransactionSet;
        uint selectorTransactionSet = uint128(slot.originalSelectorSlotsLength);
        uint selectorSlotLength = uint128(slot.originalSelectorSlotsLength >> 128);
        if(selectorSlotLength > 0) {
            slot.selectorSlot = ds.selectorSlots[selectorTransactionSet];
        }
        // loop through interchange cut        
        for(uint interchangeSetIndex; interchangeSetIndex < _interchangeSet.length; interchangeSetIndex++) {
            bytes memory facetCut = _interchangeSet[interchangeSetIndex];
            require(facetCut.length > 20, "Missing segment or selector info.");
            bytes32 currentSlot;            
            assembly { 
                currentSlot := mload(add(facetCut,32)) 
            }
            bytes32 newSegment = bytes20(currentSlot);            
            uint numSelectors = (facetCut.length - 20) / 4;
            uint position = 52;
            
            // adding or replacing functions
            if(newSegment != 0) {                
                // add and replace selectors
                for(uint selectorIndex; selectorIndex < numSelectors; selectorIndex++) {
                    bytes4 selector;
                    assembly { 
                        selector := mload(add(facetCut,position)) 
                    }
                    position += 4;                    
                    bytes32 oldSegment = ds.gsge[selector];                    
                    // add
                    if(oldSegment == 0) {                            
                        ds.gsge[selector] = newSegment | bytes32(selectorSlotLength) << 64 | bytes32(selectorTransactionSet);                            
                        slot.selectorSlot = slot.selectorSlot & ~(CLEAR_SELECTOR_MASK >> selectorSlotLength * 32) | bytes32(selector) >> selectorSlotLength * 32;                            
                        selectorSlotLength++;
                        if(selectorSlotLength == 8) {
                            ds.selectorSlots[selectorTransactionSet] = slot.selectorSlot;                                
                            slot.selectorSlot = 0;
                            selectorSlotLength = 0;
                            selectorTransactionSet++;
                            slot.newSlot = false;
                        }
                        else {
                            slot.newSlot = true;
                        }                          
                    }                    
                    // replace
                    else {
                        require(bytes20(oldSegment) != bytes20(newSegment), "Function cut to same segment.");
                        ds.gsge[selector] = oldSegment & CLEAR_ADDRESS_MASK | newSegment;
                    }                                        
                }
            }
            // remove functions
            else {                
                for(uint selectorIndex; selectorIndex < numSelectors; selectorIndex++) {
                    bytes4 selector;
                    assembly { 
                        selector := mload(add(facetCut,position)) 
                    }
                    position += 4;                    
                    bytes32 oldSegment = ds.gsge[selector];
                    require(oldSegment != 0, "Function doesn't exist. Can't remove.");
                    if(slot.selectorSlot == 0) {
                        selectorTransactionSet--;
                        slot.selectorSlot = ds.selectorSlots[selectorTransactionSet];
                        selectorSlotLength = 8;
                    }
                    slot.oldSelectorSlotsIndex = uint64(uint(oldSegment));
                    slot.oldSelectorSlotIndex = uint32(uint(oldSegment >> 64));                    
                    bytes4 lastSelector = bytes4(slot.selectorSlot << (selectorSlotLength-1) * 32);                     
                    if(slot.oldSelectorSlotsIndex != selectorTransactionSet) {
                        slot.oldSelectorSlot = ds.selectorSlots[slot.oldSelectorSlotsIndex];                            
                        slot.oldSelectorSlot = slot.oldSelectorSlot & ~(CLEAR_SELECTOR_MASK >> slot.oldSelectorSlotIndex * 32) | bytes32(lastSelector) >> slot.oldSelectorSlotIndex * 32;                                                
                        ds.selectorSlots[slot.oldSelectorSlotsIndex] = slot.oldSelectorSlot;                        
                        selectorSlotLength--;                            
                    }
                    else {
                        slot.selectorSlot = slot.selectorSlot & ~(CLEAR_SELECTOR_MASK >> slot.oldSelectorSlotIndex * 32) | bytes32(lastSelector) >> slot.oldSelectorSlotIndex * 32;
                        selectorSlotLength--;
                    }
                    if(selectorSlotLength == 0) {
                        delete ds.selectorSlots[selectorTransactionSet];                                                
                        slot.selectorSlot = 0;
                    }
                    if(lastSelector != selector) {                      
                        ds.gsge[lastSelector] = oldSegment & CLEAR_ADDRESS_MASK | bytes20(ds.gsge[lastSelector]); 
                    }
                    delete ds.gsge[selector];
                }
            }
        }
        uint newSelectorSlotsLength = selectorSlotLength << 128 | selectorTransactionSet;
        if(newSelectorSlotsLength != slot.originalSelectorSlotsLength) {
            ds.selectorTransactionSet = newSelectorSlotsLength;            
        }        
        if(slot.newSlot) {
            ds.selectorSlots[selectorTransactionSet] = slot.selectorSlot;                        
        }
        emit interchangeSet(_interchangeSet);
    }
}
