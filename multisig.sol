//Deployed Contract address: 0x892D0A143BF4e326b81F5710a0CCEC854370090f


// Multisig contract to implement a 2-out-of-2 multisig wallet 

pragma solidity ^0.6.1;
pragma experimental ABIEncoderV2;

contract MultiSigWallet{
    
    address private main_owner;  //owner is the main owner
    uint8 private owner_count;
    mapping(address => uint8) public owners;  //This mapping will contain the two owners
    
    constructor() public{
        main_owner = msg.sender;
        owner_count = 1;
        owners[main_owner] = 1; //Adding main owner to owners mapping
    }
    
    struct transferState{  //To store the state of the pending transfers
        address payable receiver;
        uint256 amt;
        address sender;
    }
    
    transferState[] public pendingStates; //Using an array and not a mapping so I can delete the structure after the pending transfer is done
    
    modifier isMainOwner(){  //function to check if user is the main owner
        require(msg.sender == main_owner);
        _;
    }
    
    modifier isOwner(){
        require(owners[msg.sender] == 1);
        _;
    }
    
    function addSecondOwner(address add2) public isMainOwner {  //function to add the second woner (can only be executed by the main owner)
        require(owner_count == 1);  //Don't allow more than 2 owners since this is a 2-out-of-2 multisig wallet
        owners[add2] = 1;
        owner_count = 2;
    }
    
    receive () external payable{}   //Function to deposit money into this contract account
    
    function initiateTransfer(address payable receiver, uint256 amt) public isOwner{  //Function to initiate transfer by any one user
        //require(address(this).balance >= amt); // we can remove this line
        require(amt > 0);
        pendingStates.push(transferState(receiver, amt, msg.sender));
    }
    
    function pendingTransfers() public isOwner view returns(transferState[] memory){ //Function to read the pendingStates array for pending transfers
        return pendingStates;
    }
    
    function deleteIndexFromPendingStates(uint8 index) internal {
        uint pendingStatesLength = pendingStates.length;
        
        if (pendingStatesLength == 1) {
            delete pendingStates; // solidity's way of saying pendingStates = []
            return;
        }
        
        // put last element in array[index]
        pendingStates[index] = pendingStates[pendingStatesLength-1];
        //delete pendingStates[pendingStatesLength-1];
        pendingStates.pop();
    }
    
    function authorizePendingTransfer(uint8 index) public isOwner{
        require(pendingStates[index].sender != msg.sender);  //The authorizing owner is not the owner who initiated this transfer
        require(address(this).balance >= pendingStates[index].amt);
        pendingStates[index].receiver.transfer(pendingStates[index].amt);
        deleteIndexFromPendingStates(index);  //Deleting this transaction from the pendingStates array since this transaction is now completed
    }
    
    function checkBalance() public view returns(uint256) {
        return address(this).balance;
    }

}