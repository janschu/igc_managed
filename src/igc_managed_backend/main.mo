import Principal "mo:base/Principal";
import AssocList "mo:base/AssocList";
import List "mo:base/List";
import Error "mo:base/Error";
import Nat "mo:base/Nat";
import Text "mo:base/Text";
import Debug "mo:base/Debug";
import ogcActor "../lib/ogcAPI/ogcActor";
import Cycles "mo:base/ExperimentalCycles";
import Types "types";
import H "../lib/helper/helper";
import HTTP "../lib/helper/httpHelper";
import IC "./ic.types";

shared({caller=initializer}) actor class Main() {

    let defaultShare = 1_000_000_000_000;
    // The main controller
    private let ic: IC.Self = actor "aaaaa-aa";

    // the registered users
    private stable var userList: AssocList.AssocList<Principal,Types.UserEntry> = List.nil();
    // initializer is allways added as 'admin'
    userList := AssocList.replace<Principal,Types.UserEntry>(userList, initializer, Principal.equal, ?{name = "admin"; role = #admin; cycle_share = 0; ogcCanister = null}).0;

    // add a new user - just by the initializer
    // canister is empty by default
    public shared ({caller}) func addUser (userPal: Principal, userName: Text, userRole: ?Types.Role, userCyles: ?Nat ): async () {
        // only admins can add users
        switch (AssocList.find<Principal,Types.UserEntry>(userList, caller, Principal.equal)) {
            case(?caller_entry) {
                switch (caller_entry.role){
                    case (#admin) {
                        // admins add a new entry
                        switch (AssocList.find<Principal,Types.UserEntry>(userList, userPal, Principal.equal)) {
                            case (?user_entry) {
                                throw Error.reject("User already in the list");
                            };
                            case (_) {
                                let user_entry : Types.UserEntry = {
                                    name = userName;
                                    role = switch (userRole) {case null {#user}; case (?r) {r}};
                                    cycle_share = switch (userCyles) {case null {defaultShare}; case (?c) {c}};
                                    ogcCanister = null;
                                };
                                userList := AssocList.replace<Principal,Types.UserEntry>(userList, userPal, Principal.equal, ?user_entry).0;    
                            };
                        };
                    };
                    case (#user) {
                        throw Error.reject("Users cannot add new users - only admin");
                    };
                };
            };
            case (_) {
                throw Error.reject("Caller is not registered");
            }; 
        };
    };

    // users can upload a new IGC File this is sent to the owners canister
    public shared ({caller}) func uploadIGC (owner: Principal, igcText: Text) : async () {
        Debug.print("Caller: " # Principal.toText(caller)); // not of relevance
        Debug.print("Owner: " # Principal.toText(owner));

        // try to obtain entry from userList
        switch (AssocList.find<Principal,Types.UserEntry>(userList,owner,Principal.equal)) {
            // if registered
            case (?user_entry) {
                switch (user_entry.role) {
                    // only user can add data
                    case (#user) {
                        switch (user_entry.ogcCanister) {
                            // if canister exists, the add track
                            case (?ogc_canister) {
                                let act: ogcActor.ogcActor = ogc_canister.ogcActor;
                                let msg :Text = await act.uploadIGC(igcText);
                                Debug.print(msg);
                            };
                            // if canister is not available, create the new one
                            case (_) {
                                let ogcCan :Types.OgcCanister = await newCanister(caller,owner,user_entry.cycle_share);
                                // modify entry
                                userList := AssocList.replace<Principal,Types.UserEntry>(userList, owner, Principal.equal, ?{name = user_entry.name; role = user_entry.role; cycle_share = 0; ogcCanister = ?ogcCan}).0;
                                // add track
                                let msg :Text = await ogcCan.ogcActor.uploadIGC(igcText);
                                Debug.print(msg);
                            };
                        };
                    };
                    // admins throw error
                    case (_) {
                        throw Error.reject("Admin cannot add tracks");
                    };
                };
            };
            // if no user -> throw Error
            case (_) {
                throw Error.reject("Cannot add track - user is not registered");
            };
        };
    }; 

    // resolves the OGC API URL
    public shared query ({caller}) func getOgcURL (owner: Principal, path: Text, format: H.Representation, local: Bool) : async Text {
        Debug.print("Calling getOgcURL: " # path);
        // Find User Entry
        switch (AssocList.find<Principal,Types.UserEntry>(userList,owner,Principal.equal)){
            // There is no entry
            case null {
                throw Error.reject("Owner is not registered - Owner:" # Principal.toText(owner)) ;
            };
            // There is one entry 
            case (?entry) {
                switch(entry.ogcCanister){
                    // There is no canister for the entry
                    case(null) {
                        throw Error.reject("Owner is registered, but has no container. Owner: " # Principal.toText(owner));
                    };
                    // There is a canister for the entry
                    case(?ogcCanister) {
                        let resp : Text = HTTP.buildUrl (path, ogcCanister.canister, local, format);
                        Debug.print (resp);
                        return resp;
                    };
                };
            };
        };
    };

    // get the URL for icp dashboard
    public shared query ({caller}) func getIcpDashboard (owner: Principal) : async Text {
        // Find User Entry
        switch (AssocList.find<Principal,Types.UserEntry>(userList,owner,Principal.equal)){
            // There is no entry
            case null {
                throw Error.reject("Owner is not registered - Owner:" # Principal.toText(owner)) ;
            };
            // There is one entry 
            case (?entry) {
                switch(entry.ogcCanister){
                    // There is no canister for the entry
                    case(null) {
                        throw Error.reject("Owner is registered, but has no container. Owner: " # Principal.toText(owner));
                    };
                    // There is a canister for the entry
                    case(?ogcCanister) {
                        let resp : Text = Text.concat("https://dashboard.internetcomputer.org/canister/", Principal.toText(ogcCanister.canister));
                        return resp;
                    };
                };
            };
        };
    };

    public shared query ({caller}) func getUser (userPal: Principal) : async {userpal: Principal; username:Text; userrole: Types.Role } {
        switch (AssocList.find<Principal,Types.UserEntry>(userList,userPal,Principal.equal)){
            case null {
                throw Error.reject("User cannot be found " # Principal.toText(userPal)) ;
            }; 
            case (?entry) {
                return {
                    userpal = userPal;
                    username = entry.name;
                    userrole = entry.role;
                };
            }; 
        };     
    };

    public shared ({caller}) func getCanisterStatus (userPal: Principal) : async Types.CanisterRunningState {
        switch (AssocList.find<Principal,Types.UserEntry>(userList,userPal,Principal.equal)){
            case null {
                throw Error.reject("User cannot be found " # Principal.toText(userPal)) ;
            };
            case (?entry) {
                switch (entry.ogcCanister) {
                    case null {
                        return #notExisting;
                    };
                    case (?can) {
                        let state: IC.canister_status_response = await ic.canister_status({canister_id=can.canister;});
                        switch (state.status) {
                            case (#running) {
                                return #Running;
                            };
                            case (_) {
                                return #notRunning;
                            };
                        };
                    };
                };
            };
        };
    };

    public shared ({caller}) func stopCanister (userPal: Principal) : async () {
        Debug.print("Stop Canister");
        switch (AssocList.find<Principal,Types.UserEntry>(userList,userPal,Principal.equal)){
            case null {
                throw Error.reject("User cannot be found " # Principal.toText(userPal)) ;
            };
            case (?entry) {
                switch (entry.ogcCanister) {
                    case (?ogccan) {  
                        await ic.stop_canister({canister_id = ogccan.canister;});
                        Debug.print("Canister stopped");
                    };
                    case (_) {
                        throw Error.reject("No canister to be stopped") ;    
                    };
                };
            };
        };      
    };


    public shared ({caller}) func startCanister (userPal: Principal) : async () {
        Debug.print("Start Canister");
        switch (AssocList.find<Principal,Types.UserEntry>(userList,userPal,Principal.equal)){
            case null {
                throw Error.reject("User cannot be found " # Principal.toText(userPal)) ;
            };
            case (?entry) {
                switch (entry.ogcCanister) {
                    case (?ogccan) {  
                        await ic.start_canister({canister_id = ogccan.canister;});
                        Debug.print("Canister started");
                    };
                    case (_) {
                        let ogcCan :Types.OgcCanister = await newCanister(caller,userPal,entry.cycle_share);
                        // modify entry
                        userList := AssocList.replace<Principal,Types.UserEntry>(userList, userPal, Principal.equal, ?{name = entry.name; role = entry.role; cycle_share = 0; ogcCanister = ?ogcCan}).0;                                
                        Debug.print("Canister created");
                    };
                };
            };
        };      
    };


    public shared ({caller}) func deleteIGC (owner: Principal, trackId: Text) : async Text {

        Debug.print("Caller: " # Principal.toText(caller));
        Debug.print("Owner: " # Principal.toText(owner));
        var msg : Text = "";

        // try to obtain entry from canisterMap
        // Find User Entry
        switch (AssocList.find<Principal,Types.UserEntry>(userList,owner,Principal.equal)){
            // no user registered
            case null {
                throw Error.reject("User cannot be found " # Principal.toText(owner)) ;
            };
            // user is present, but value might be null
            case (?entry) {
                switch(entry.ogcCanister){
                    // user registered, but wrong canister
                    case(null) {
                        throw Error.reject("User (" # Principal.toText(owner) # ") is not owner of a canister");
                    };
                    case(?ogcCanister){
                        // delete entry
                        let act: ogcActor.ogcActor = ogcCanister.ogcActor;
                        msg := await act.deleteTrackById(trackId);
                    };
                };
            };
        };
        return msg;
    };

  // create a new canister with actor
  // mainly taken from https://medium.com/dfinity/dynamically-create-canister-smart-contracts-in-motoko-d3b38a748c07
  private func newCanister (caller: Principal, owner: Principal, cycleShare: Nat) : async Types.OgcCanister {
    Cycles.add(cycleShare);
    let ogcAct = await ogcActor.ogcActor(owner); 
    // the new canister Id
    let canisterId : Principal= Principal.fromActor(ogcAct);
    // let self:Principal = Principal.fromActor(Main);
    // let controllers: ?[Principal] = ?[canisterId, caller, self];
    // await ic.update_settings(({canister_id = canisterId; settings = {
    //     controllers = controllers;
    //     freezing_threshold = null;
    //     memory_allocation = null;
    //     compute_allocation = null;
    //     }}));
    // let value : types.contVal = {ogcCont=?{container=canisterId;ogcActor=ogcAct;};};
    // canisterMap.put(owner, value);
    return {canister=canisterId; ogcActor=ogcAct;}; 
  };   
};