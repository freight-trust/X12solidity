/**SPDX-License-identifer:  MIT*/
pragma solidity >=0.6.4 <0.7.0;



contract InterchangeStorageContract {

    struct InterchangeStorage {
        
        // owner of the contract
        address contractOwner;

        // maps function selectors to the gsge that execute the functions.
        // and maps the selectors to the slot in the selectorSlots array.
        // and maps the selectors to the position in the slot.
        // func selector => address segment, uint64 slotsIndex, uint64 slotIndex
        mapping(bytes4 => bytes32) gsge;

        // array of slots of function selectors.
        // each slot holds 8 function selectors.
        mapping(uint => bytes32) selectorSlots;  

        // uint128 numSelectorsInSlot, uint128 selectorTransactionSet
        // selectorTransactionSet is the number of 32-byte slots in selectorSlots.
        // selectorSlotLength is the number of selectors in the last slot of
        // selectorSlots.
        uint selectorTransactionSet;

        // Used to query if a contract implements an interface.
        // Used to implement ERC-165.
        mapping(bytes4 => bool) supportedInterfaces;
    }
    

    function interchangeStorage() internal pure returns(InterchangeStorage storage ds) {
        // ds_slot = keccak256("interchange.standard.interchange.storage");
        assembly { ds_slot := 0xc8fcad8db84d3cc18b4c41d551ea0ee66dd599cde068d998e57d5e09332c131c }
    }
}
