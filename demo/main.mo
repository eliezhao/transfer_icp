import A "./Account";
import T "./Types";
import Blob "mo:base/Blob";
import Debug "mo:base/Debug";
import Error "mo:base/Error";
import Hash "mo:base/Hash";
import HashMap "mo:base/HashMap";
//import ICP "./ICPLedger";
import Int "mo:base/Int";
import List "mo:base/List";
import Nat "mo:base/Int64";
import Nat64 "mo:base/Nat64";
import Option "mo:base/Option";
import Principal "mo:base/Principal";
import Text "mo:base/Text";
import TimeBase "mo:base/Time";
import Array "mo:base/Array";
import Cycles "mo:base/ExperimentalCycles";
import Time "mo:base/Time";
import Prim "mo:⛔";
import Nat8 "mo:base/Nat8";

actor demo{
    
    public type Memo = Nat64;

    public type Token = {
        e8s : Nat64;
    };

    public type TimeStamp = {
        timestamp_nanos: Nat64;
    };

    public type AccountIdentifier = Blob;
    
    public type SubAccount = Blob;

    public type BlockIndex = Nat64;

    public type TransferError = {
        #BadFee: {
            expected_fee: Token;
        };
        #InsufficientFunds: {
            balance: Token;
        };
        #TxTooOld: {
            allowed_window_nanos: Nat64;
        };
        #TxCreatedInFuture;
        #TxDuplicate : {
            duplicate_of: BlockIndex;
        };
    };

    public type TransferArgs = {
        memo: Memo;
        amount: Token;
        fee: Token;
        from_subaccount: ?SubAccount;
        to: AccountIdentifier;
        created_at_time: ?TimeStamp;
    };

    public type TransferResult = {
        #Ok: BlockIndex;
        #Err: TransferError;
    };

    public type Address = Blob;

    public type AccountBalanceArgs = {
        account : Address
    };

    public type Ledger = actor{
        transfer : TransferArgs -> async TransferResult;
        account_balance : query AccountBalanceArgs -> async Token;
    };

    var main_account_principal = Principal.fromText("slqa4-73acs-65lmr-d52by-ugflp-4dm7p-i2omo-yrw65-5d7mn-qqcbh-lae");
    var default_sub_account_blob = Blob.fromArray(Array.freeze<Nat8>(Array.init<Nat8>(32, 0x00:Nat8)));
    var sub_account_metadata = Array.init<Nat8>(32, 0x00:Nat8);
    sub_account_metadata[0] := 0x01 : Nat8;

    var sub_account_blob = Blob.fromArray(Array.freeze<Nat8>(sub_account_metadata));
    var sub_account_identifier = A.accountIdentifier(main_account_principal, sub_account_blob);
    var canister_account_identifier = A.accountIdentifier(main_account_principal, default_sub_account_blob);
    let ledger : Ledger = actor("ryjl3-tyaaa-aaaaa-aaaba-cai");

    public query func getCycleBalance() : async Nat{
        Cycles.balance()
    };

    public query({caller}) func accountIdentifiers() : async [Text]{
        assert(caller == main_account_principal);
        [
            debug_show(sub_account_identifier),
            debug_show(canister_account_identifier)
        ]
    };

    public shared({caller}) func init() : async Text{
        sub_account_identifier := A.accountIdentifier(Principal.fromActor(demo), sub_account_blob);
        canister_account_identifier := A.accountIdentifier(Principal.fromActor(demo), default_sub_account_blob);
        "subaccount identifier : " # debug_show(sub_account_identifier)
        #
        "\n"
        #
        "canister_account_identifier : " # debug_show(canister_account_identifier)
    };

    public shared({caller}) func transferToSubaccount() : async Text{
        assert(caller == main_account_principal);
        let args = {
            memo = Prim.time();
            amount = { e8s = 90_000 : Nat64 }; // 0.001 ICP 
            fee = { e8s = 10_000 : Nat64 };
            from_subaccount = null;
            to = sub_account_identifier;
            created_at_time = null;
        };
        switch(await ledger.transfer(args)){
            case(#Ok(idx)){ "transfer successfully on block : " # debug_show(idx) };
            case(#Err(error)){ debug_show(error) };
        }
    };

    public shared({caller}) func transferToCanister() : async Text{
        assert(caller == main_account_principal);
        let args = {
            memo = Prim.time();
            amount = { e8s = 80_000 : Nat64 }; // 0.001 ICP 
            fee = { e8s = 10_000 : Nat64 };
            from_subaccount = ?sub_account_blob;
            to = canister_account_identifier;
            created_at_time = null;
        };
        switch(await ledger.transfer(args)){
            case(#Ok(idx)){ "transfer successfully on block : " # debug_show(idx) };
            case(#Err(error)){ debug_show(error) };
        }
    };

    public shared({caller}) func transferBack(
        to : AccountIdentifier
    ) : async Text{
        assert(caller == main_account_principal);
        // f40af3e0cfae1b50a08fde5ac68360a1c513f84417bc5f797fdb93f8361dffdf
        let args = {
            memo = Prim.time();
            amount = { e8s = 80_000 : Nat64 }; // 0.001 ICP 
            fee = { e8s = 10_000 : Nat64 };
            from_subaccount = null;
            to = to;
            created_at_time = null;
        };
        switch(await ledger.transfer(args)){
            case(#Ok(idx)){ "transfer successfully on block : " # debug_show(idx) };
            case(#Err(error)){ debug_show(error) };
        }
    };

    public shared({caller}) func getBalance() : async Text{
        "canister icp balance : " # debug_show(await ledger.account_balance({
            account = canister_account_identifier
        }))
        #
        "subaccount icp balance : " # debug_show(await ledger.account_balance({
            account = sub_account_identifier
        }))
    };

    public query func test():async Text{
        debug_show(A.accountIdentifier(main_account_principal, default_sub_account_blob))
    }

}