// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0 <0.9.0;


//0xe84d601e5d945031129a83e5602be0cc7f182cf3 ,  0xd605b974117fb59ad3159cba16df7d57e5b3fe5f , 0x14a89b696ced1ca0e94956485290739db74cdb07


// contract address - 0x20b335d072f8c37dc026068c88cca628822da134
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract AccRegistry {

    event Deposit(address indexed sender, uint amount);
    event Submit(uint indexed txId);
    event Approve(address indexed owner, uint indexed txId);
    event Revoke(address indexed owner, uint indexed txId);
    event Execute(uint indexed txId);
    event ReqUpdate(uint256 req);
    event OwnerAddition(address indexed owner);
    event OwnerRemoval(address indexed owner);
    event AdminTransfer(address indexed newAdmin);

    address public admin;

    address[] public owners;
    mapping(address => bool) public isOwner;
    uint256 public required;

    modifier onlyAdmin() {
        require(msg.sender == admin, "Admin restricted function");
        _;
    }

    modifier notNull(address _address) {
        require(_address != address(0), "Specified destination doesn't exist");
        _;
    }

    modifier ownerExistsMod(address owner) {
        require(isOwner[owner] == true, "This owner doesn't exist");
        _;
    }

    modifier notOwnerExistsMod(address owner) {
        require(isOwner[owner] == false, "This owner already exists");
        _;
    }

    constructor(address[] memory _owners){
        admin = msg.sender;

        require(_owners.length > 2,"more than 2 owners required");


        for(uint i; i < _owners.length ; i++){
            address owner = _owners[i];

            require(owner != address(0),"invalid owner");
            require(!isOwner[owner],"owner is not unique");

            isOwner[owner] = true;
            owners.push(owner);

        }

        uint num = SafeMath.mul(_owners.length, 60);
    
        required = SafeMath.div(num,100);

    }

    function addOwner(address owner)
        public
        onlyAdmin
        notNull(owner)
        notOwnerExistsMod(owner)
    {
  
        isOwner[owner] = true;
        owners.push(owner);

   
        emit OwnerAddition(owner);


        updateReq(owners);
    }

    function removeOwner(address owner)
        public
        onlyAdmin
        notNull(owner)
        ownerExistsMod(owner)
    {

        isOwner[owner] = false;

        
        for (uint256 i = 0; i < owners.length - 1; i++)
            if (owners[i] == owner) {
                owners[i] = owners[owners.length - 1];
                break;
            }
        owners.pop();

     
        updateReq(owners);
    }

    function transferOwner(address _from, address _to)
        public
        onlyAdmin
        notNull(_from)
        notNull(_to)
        ownerExistsMod(_from)
        notOwnerExistsMod(_to)
    {
  
        for (uint256 i = 0; i < owners.length; i++)
            if (owners[i] == _from) {
            
                owners[i] = _to;
                break;
            }

        

    
        isOwner[_from] = false;
        isOwner[_to] = true;
    
        emit OwnerRemoval(_from);
        emit OwnerAddition(_to);
    }


    function renounceAdmin(address newAdmin) public onlyAdmin {
        admin = newAdmin;

        emit AdminTransfer(newAdmin);
    }






    function updateReq(address[] memory _owners) internal {
        uint256 num = SafeMath.mul(_owners.length, 60);
        required = SafeMath.div(num, 100);

        emit ReqUpdate(required);
    }



}
