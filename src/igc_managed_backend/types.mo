import Principal "mo:base/Principal";
import TR "../lib/igcData/igcTrack";
import TM "../lib/igcData/igcTrackMap";
import http "../lib/helper/httpHelper";

module {
    
    public type UserEntry = {
        name: Text;
        role: Role;
        cycle_share: Nat;
        ogcCanister: ?OgcCanister;
    };

    public type Role = {
        #admin;
        #user;
    };
    
    public type OgcCanister = {
        canister: Principal;
        ogcActor: OgcActorType;
    };

    public type OgcActorType = actor {
        getOGCRootMetadata: shared query () -> async TM.Metadata;
        uploadIGC: shared (Text) -> async Text;
        getMetadataById: shared query (Text ) -> async ?TR.Metadata;
        getTrackList: shared query () -> async [TR.Metadata];
        getTrackLineGeoJSON: shared query (Text) -> async Text;
        http_request: shared query (http.HttpRequest) -> async http.HttpResponse ;
        deleteTrackById : shared Text -> async Text;
    };

    public type CanisterRunningState = {
        #notExisting;
        #notRunning;
        #Running;
    };
};