pragma solidity 0.4.15;
// Contract is highest object that can be declared in solidity
contract mortal{
    // Contract will not be deployed to blockchain, unless owner address is saved
    address public owner;
    function mortal(){
        //Set owner to the sender of this contract
        owner = msg.sender;
    }
    
    // Creaete function modifier onlyOwner and assign owner to the contract creator
    modifier onlyOwner{
        if (msg.sender != owner){
            revert();
        }else{
            _;
        }
    }
    // Only the owner of this contract can kill it
    function kill() onlyOwner{
        suicide(owner);
    }
}

contract Punchies is mortal() {
    
    struct Customer {
        bool exists;
        uint id;
        uint punchies;
    }
    
    struct User {
        bool exists;
        uint id;
        
        // Used to iterate through memberships
        uint numberOfMemberships;
        
        // Mapping will start at 1
        mapping( uint => bytes32 ) memberships;
    }
    
    struct Tier {
        bool exists;
        uint punchiesRequired;
        bytes32 rewardDescription;
    }
    
    
    struct Store {
        bool exists;
        bytes32 storeName;
        uint[] customerNumbers;
        uint[] tierKeys;
        mapping( uint => Tier ) tiers;
        mapping( uint => Customer ) customers;
        
    }
    
    event StoreEvent (
        bytes32 _storeName,
        bytes32 _changeType
    );
    
    event UserEvent (
        uint _id,
        bytes32 _changeType
    );
    
    event TierEvent (
        bytes32 _storeName,
        uint _punchiesNeeded,
        bytes32 _tierSummary,
        bytes32 _changeType
    );

    mapping( bytes32 => Store ) public stores;
    mapping( uint => User ) public users;
    
    
    // Add Store
    function addStore(bytes32 _storeName) returns ( string, uint, bytes32 ) {
        if ( stores[_storeName].exists ) {
            StoreEvent("", "prevented duplicate");
            return ( "Error: Store already exists. Please choose a different store name.", 1, "" );
        }
        
        Store memory newStore;
        newStore.storeName = _storeName;
        newStore.exists = true;
        stores[_storeName] = newStore;
        StoreEvent(_storeName, "added store");
        return ( "Success: New store created.", 0, _storeName );
    }
    
    // Get Store
    function getStore( bytes32 _storeName ) constant returns ( string, uint, bool, bytes32 ) {
        Store storage currentStore = stores[_storeName];
        
        if ( !currentStore.exists ) {
            StoreEvent(_storeName, "invalid store id");
            return ( "Error: specified store does not exist.", 1, false, "" );
        }
        
        StoreEvent(_storeName, "store found");
        return( "Success: fetched store.", 0, currentStore.exists, currentStore.storeName );
    }
    
    // Delete Store
    function deleteStore( bytes32 _storeName ) public returns ( string, uint ) {
        Store storage currentStore = stores[_storeName];
        
        if ( currentStore.exists != true ) {
            StoreEvent(_storeName, "invalid store");
            return ( "Error: Specified store does not exist.", 1 );
        }
        
        if ( currentStore.tierKeys.length > 0 ) {
            for( uint i = 0; i < currentStore.tierKeys.length; i++ ) {
                uint tierKey = currentStore.tierKeys[i];
                delete currentStore.tiers[tierKey];
            }
        }
        
        if ( currentStore.customerNumbers.length > 0 ) {
            for( uint j = 0; j < currentStore.customerNumbers.length; j++ ) {
                uint customerIndex = currentStore.customerNumbers[j];
                delete currentStore.customers[customerIndex];
            }
        }
        
        delete stores[_storeName];
        
        if( stores[_storeName].exists != true ) {
            StoreEvent(_storeName, "deleted store");
            return ( "Success: Store deleted.", 0 );
        }
        
        return ( "Error: could not delete store.", 1 );
    }
    
    // Add Tier
    function addTier( bytes32 _storeName, uint _tierRequirement, bytes32 _tierDescription) returns ( string, uint ) {
        Store storage currentStore = stores[_storeName];
        
        // Tier memory newTier;
        
        currentStore.tierKeys.push(_tierRequirement);
        currentStore.tiers[_tierRequirement].punchiesRequired = _tierRequirement;
        currentStore.tiers[_tierRequirement].rewardDescription = _tierDescription;
        currentStore.tiers[_tierRequirement].exists = true;
        
        
        if ( currentStore.tiers[_tierRequirement].exists != true ) {
  	      	TierEvent(_storeName, _tierRequirement, _tierDescription, "Tier Creation Error");
	          return ( "Error processing new tier. Please try again.", 1 );
        }
        
        TierEvent( _storeName, _tierRequirement, _tierDescription, "Created Tier" );
        return ( "Success: Tier added.", 0 );
        
    }
    
    
    // Remove Tier
    function deleteTier( bytes32 _storeName, uint _tierIndex ) returns ( string, uint ) {
        Store storage currentStore = stores[_storeName];
        
        if ( currentStore.tiers[_tierIndex].exists != true ) {
            TierEvent( _storeName, 0, "", "Tier Deletion Error");
            return ( "Error: Tier does not exist.", 1 );
        }
        
        // if ( _tierIndex > currentStore.numberOfTiers || _tierIndex <= 0 ){
            
        //     TierEvent( _storeName, 0, "", "Tier Deletion Error" );
        //     return ( "Invalid tier index.", 1 );
        // }
        
        // for ( uint i = _tierIndex; i < currentStore.numberOfTiers; i++ ) {
        //     currentStore.tiers[i] = currentStore.tiers[i+1];
        // }
        
        for ( uint i = 0; i < currentStore.tierKeys.length; i++ ) {
            if( currentStore.tierKeys[i] == _tierIndex ) {
                for ( uint j = i; j < currentStore.tierKeys.length - 1; j++ ) {
                    currentStore.tierKeys[j] = currentStore.tierKeys[j+1];
                }
            }
            
        }
        
        delete currentStore.tierKeys[currentStore.tierKeys.length - 1];
        delete currentStore.tiers[_tierIndex];
        TierEvent( _storeName, 0, "", "Deleted Tier" );
        
        return ( "Success: Tier removed.", 0 );
        
    }
    
    // Add punchies
    function addPunchie( bytes32 _storeName, uint _id, uint _punchies ) returns ( string, uint ) {
        Store storage currentStore = stores[_storeName];
        
        // Customer does not exist in store and User does not exist
        if ( currentStore.customers[_id].exists != true && users[_id].exists != true ) {
            Customer memory newCustomer;
            newCustomer.id = _id;
            newCustomer.punchies = _punchies;
            newCustomer.exists = true;
            currentStore.customers[_id] = newCustomer;
            currentStore.customerNumbers.push(newCustomer.id);
            
            // Initialize new user
            User memory newUser;
            newUser.id = _id;
            newUser.exists = true;
            newUser.numberOfMemberships = 1;
            users[_id] = newUser;
            
            // Get newly created user and add to memberships mapping
            User storage currentUser = users[_id];
            currentUser.memberships[1] = _storeName;
            
            UserEvent(_id, "user/customer created");
            return ( "Success: New Customer and punchie(s) added.", 0 );
        }
        
        // Customer does not exist in store but User exists
        if ( currentStore.customers[_id].exists != true && users[_id].exists == true ) {
            Customer memory existingUser;
            existingUser.id = _id;
            existingUser.punchies = _punchies;
            existingUser.exists = true;
            currentStore.customers[_id] = existingUser;
            currentStore.customerNumbers.push(existingUser.id);
            
            users[_id].numberOfMemberships++;
            uint newStoreIndex = users[_id].numberOfMemberships;
            users[_id].memberships[newStoreIndex] = _storeName;
            
            UserEvent(_id, "New customer created");
            return ( "Success: New Customer and punchie(s) added.", 0 );
            
        }
        
        
        // Returning customer
        if ( currentStore.customers[_id].exists == true && users[_id].exists == true ) {
            currentStore.customers[_id].punchies += _punchies;
            UserEvent(_id, "Punchies added");
            return ( "Success: Customer punchies updated.", 0 );
        }
        
        UserEvent(_id, "Failed to add punchies");
        return ( "Error: Could not add punchies to specified customer.", 1 );
        
        
    }
    
    // Redeems punchie based on current tier
    function redeem( uint _id, bytes32 _storeName, uint _tierIndex ) returns ( string, uint, uint ) {
        Store storage currentStore = stores[_storeName];
        
        if( currentStore.tiers[_tierIndex].exists != true ) {
            UserEvent( _id, "invalid redeem tier" );
            return ( "Error: Cannot Redeem. Invalid tier index.", 1, 0 );
        }
        
        if( currentStore.tiers[_tierIndex].punchiesRequired > currentStore.customers[_id].punchies ) {
            UserEvent( _id, "insufficient punchies" );
            return ( "Error: Insufficient punchies.", 1, 0 );
        }
        
        currentStore.customers[_id].punchies -= currentStore.tiers[_tierIndex].punchiesRequired;
        UserEvent( _id, "punchies redeemed" );
        return ( "Success: Punchies redeemed.", 0, currentStore.customers[_id].punchies );
    }
    
}
















