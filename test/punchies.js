var Punchies = artifacts.require("./Punchies.sol");

contract('Punchies', function(accounts) {
	
	it("should create a store after taking in a unique identifier string", async function() {
	    let punchies = await Punchies.deployed();
	    let eventWatcher = punchies.StoreEvent();
	    let response = await punchies.addStore("testStore", {from: accounts[0]});
	    let events = eventWatcher.get();
	    
	    assert.equal(events.length, 1);
	    assert.equal(web3.toUtf8(events[0].args._storeName), "testStore");
	    assert.equal(web3.toUtf8(events[0].args._changeType), "added store");
	    eventWatcher.stopWatching();
	})
	
	it("should prevent duplicate stores from being created", async function() {
		 let punchies = await Punchies.deployed();
		 let eventWatcher = punchies.StoreEvent();
		 let response = await punchies.addStore("testStore", {from: accounts[0]});
		 let events = eventWatcher.get();
		
		 assert.equal(events.length, 1);
		 assert.equal(web3.toUtf8(events[0].args._storeName), "");
		 assert.equal(web3.toUtf8(events[0].args._changeType), "prevented duplicate");
		 eventWatcher.stopWatching();
	})
	
	//Tests that don't modify blockchain state use .call function
	//Can't use events due to no transaction being produced from a 
	// get request.
	it("should be able to retrieve stores by id", async function() {
	  let punchies = await Punchies.deployed();
	  let response = await punchies.getStore.call("testStore");
	  assert(response[1].toNumber() == 0, "Failed to get store");
	})
	
	it("should create a new tier for the specified store", async function(){
		let punchies = await Punchies.deployed();
		let eventWatcher = punchies.TierEvent();
		let response = await punchies.addTier("testStore", 5, "5 punchies", {from: accounts[0]});
		// console.log(response);
		let events = eventWatcher.get();
		
		assert.equal(events.length, 1);
		assert.equal(web3.toUtf8(events[0].args._storeName), "testStore");
		assert.equal(events[0].args._punchiesNeeded.toNumber(), 5);
		assert.equal(web3.toUtf8(events[0].args._tierSummary), "5 punchies")
		assert.equal(web3.toUtf8(events[0].args._changeType), "Created Tier");
		eventWatcher.stopWatching();
	})
	
	it("should create a new punchies user and store customer", async function(){
		let punchies = await Punchies.deployed();
		let eventWatcher = punchies.UserEvent();
		let response = await punchies.addPunchie("testStore", 6507773333, 1, {from:accounts[0]});
		let events = eventWatcher.get();
		
		assert.equal(events.length, 1);
		assert.equal(events[0].args._id.toNumber(), 6507773333);
		assert.equal(web3.toUtf8(events[0].args._changeType), "user/customer created")
		eventWatcher.stopWatching();
	})
	
	it("should add punchies to an existing customer and user", async function(){
		let punchies = await Punchies.deployed();
		let eventWatcher = punchies.UserEvent();
		let response = await punchies.addPunchie("testStore", 6507773333, 9, {from:accounts[0]});
		let events = eventWatcher.get();
		
		assert.equal(events.length, 1);
		assert.equal(events[0].args._id.toNumber(), 6507773333);
		assert.equal(web3.toUtf8(events[0].args._changeType), "Punchies added")
		eventWatcher.stopWatching();
	})
	
	it("should add punchies and create new customer from existing user", async function(){
		let punchies = await Punchies.deployed();
		let eventWatcher = punchies.UserEvent();
		// create other store
		let createStore = await punchies.addStore("otherTestStore", {from:accounts[0]});
		let response = await punchies.addPunchie("otherTestStore", 6507773333, 1, {from:accounts[0]});
		let events = eventWatcher.get();
		
		assert.equal(events.length, 1);
		assert.equal(events[0].args._id.toNumber(), 6507773333);
		assert.equal(web3.toUtf8(events[0].args._changeType), "New customer created")
		eventWatcher.stopWatching();
	})
	
	
	it("should redeem customer punchies from a given tier", async function(){
		let punchies = await Punchies.deployed();
		let eventWatcher = punchies.UserEvent();
		// create other store
		let response = await punchies.redeem(6507773333, "testStore",  5, {from:accounts[0]});
		let events = eventWatcher.get();
		
		assert.equal(events.length, 1);
		assert.equal(events[0].args._id.toNumber(), 6507773333);
		assert.equal(web3.toUtf8(events[0].args._changeType), "punchies redeemed")
		eventWatcher.stopWatching();
	})
	
	
	
	it("should delete a tier index from a store", async function(){
		let punchies = await Punchies.deployed();
		let eventWatcher = punchies.TierEvent();
		let response = await punchies.deleteTier("testStore", 5, {from:accounts[0]});
		let events = eventWatcher.get();
		
		assert.equal(events.length, 1);
		assert.equal(web3.toUtf8(events[0].args._storeName), "testStore");
		assert.equal(events[0].args._punchiesNeeded.toNumber(), 0);
		assert.equal(web3.toUtf8(events[0].args._tierSummary), "");
		assert.equal(web3.toUtf8(events[0].args._changeType), "Deleted Tier");
		eventWatcher.stopWatching();
	})
	
	
	it("should be able to delete stores", async function() {
		 let punchies = await Punchies.deployed();
		 let eventWatcher = punchies.StoreEvent();
		 let response = await punchies.deleteStore("testStore", {from: accounts[0]});
		 let events = eventWatcher.get();
		
		 assert.equal(events.length, 1);
		 assert.equal(web3.toUtf8(events[0].args._storeName), "testStore");
		 assert.equal(web3.toUtf8(events[0].args._changeType), "deleted store");
		 eventWatcher.stopWatching();
	})
	
	it("cleanup test variables", async function() {
		 let punchies = await Punchies.deployed();
		 let eventWatcher = punchies.StoreEvent();
		 let response = await punchies.deleteStore("otherTestStore", {from: accounts[0]});
		 let events = eventWatcher.get();
		
		 assert.equal(events.length, 1);
		 assert.equal(web3.toUtf8(events[0].args._storeName), "otherTestStore");
		 assert.equal(web3.toUtf8(events[0].args._changeType), "deleted store");
		 eventWatcher.stopWatching();
	})
})