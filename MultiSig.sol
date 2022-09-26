// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0 <0.9.0;


// 0x3938459e590d200dfa2e139400db95c870102f2b , 0x6a3e8753300040b0e09169053b0e7d93a99998e1 , 0x0ead86a1de353469c8155eb83d5db615cc5d1d77

// contract address - 0xb5a1eb0d1e640db2f357529c764598bcd017fb57

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./AccRegistry.sol";

contract MultiSig is AccRegistry {
    

    
    struct Transaction{
        address to;
        uint value;
        bytes data;
        bool executed;
    }

    // address[] public owners;
    // mapping(address => bool) public isOwner;
    
    // uint public required;

    Transaction[] public transactions;
    mapping(uint => mapping(address => bool)) public approved;

    modifier onlyOwner() {
        require(isOwner[msg.sender],"not Owner");
        _;
    }

    modifier txExists(uint _txId){
        require(_txId < transactions.length , "tx does not exists");
        _;
    }

    modifier notApproved(uint _txId){
        require(!approved[_txId][msg.sender],"tx already approved");
        _;
    }

    modifier notExecuted(uint _txId){
        require(!transactions[_txId].executed, "tx already executed");
        _;
    }

    constructor(address[] memory _owners) AccRegistry(_owners) {}

    receive() external payable{
        emit Deposit(msg.sender, msg.value);
    }

    function submit(address _to, uint _value, bytes calldata _data ) external onlyOwner{

        transactions.push(Transaction({
            to : _to,
            value: _value,
            data: _data,
            executed: false
        }
        ));

        emit Submit(transactions.length - 1); // first transaction will we stored at 0 then 2...
    
     }

    function approve(uint _txId) external onlyOwner txExists(_txId) notApproved(_txId) notExecuted(_txId){

        approved[_txId][msg.sender] = true;
        emit Approve(msg.sender, _txId);

    }

    function _getApprovalCount(uint _txId) private view returns(uint count){
       for(uint i; i < owners.length; i++){
           if(approved[_txId][owners[i]]){
               count += 1;
           }
       }
    }

    function execute(uint _txId) external txExists(_txId)  notExecuted(_txId){
        require(_getApprovalCount(_txId) >= required , " approvals < required");

        Transaction storage transaction = transactions[_txId];

        transaction.executed = true;

        (bool success, ) = transaction.to.call{value: transaction.value}(
            transaction.data
        );

        require(success, "tx failed");

        emit Execute(_txId);
    }

    function revoke(uint _txId) external onlyOwner txExists(_txId) notExecuted(_txId){
        require(approved[_txId][msg.sender] , "You have not approved the transaction");

        approved[_txId][msg.sender] = false;

        emit Revoke(msg.sender , _txId);
    }

}
