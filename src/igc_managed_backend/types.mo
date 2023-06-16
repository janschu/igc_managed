import Principal "mo:base/Principal";
import TR "../lib/igcData/igcTrack";
import TM "../lib/igcData/igcTrackMap";
import http "../lib/helper/httpHelper";

module {
    public type contVal = {
        ogcCont: ?ogcContainer;
    };
    
    public type ogcContainer = {
        container: Principal;
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
};