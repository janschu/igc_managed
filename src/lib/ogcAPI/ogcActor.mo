import Iter "mo:base/Iter";
import Buffer "mo:base/Buffer";
import Debug "mo:base/Debug";
import Text "mo:base/Text";
import Principal "mo:base/Principal";
import Array "mo:base/Array";

// local
import H "../helper/helper";
import http "../helper/httpHelper";
import TR "../igcData/igcTrack";
import TM "../igcData/igcTrackMap";
import OR "ogcApiRoot";
import OC "ogcApiCollections";
import OCS "ogcApiCollectionsSingle";
import OCSI "ogcApiCollectionsSingleItems";
import OCF "ogcApiConformance";
import Bool "mo:base/Bool";

shared (install) actor class ogcActor (ownerPrincipal : Principal) =
  this { 
  var trackmap : TM.TrackMap = TM.TrackMap();
  let owner: Principal = ownerPrincipal;
  // true for local dev
  let dev : Bool = true;


  public shared query func getOGCRootMetadata () : async TM.Metadata {
    return trackmap.metadata;
  };

  public shared func uploadIGC (igcText : Text) : async Text {
    let track : TR.Track = TR.parseIGCTrack(igcText);
    let newTrackId : Text = trackmap.addTrack(track);
    return (newTrackId);
    //return trackmap.getTracklist();
    //return track.getGeoJSONPointCollection();
    //let igc : IGC.IGCLog = IGC.IGCLog(igcText);
    //return igc.getGeoJSON();
  };

  public shared func deleteTrackById (trackId : Text) : async Text {
    if (trackId == "FC") {
      return "Collection of Flights cannot be deleted";
    };
    switch (trackmap.deleteTrackById(trackId)) {
      case (?success) {
        return "deleted " # success;
      };
      case (_) {
        return "track not available";
      };
    };
  };

  // is public shared needed?
  public shared query func getMetadataById (trackId : Text ) : async ?TR.Metadata {
    return p_getMetadataById(trackId);
  };

  private func p_getMetadataById (trackId: Text): ?TR.Metadata {
    switch (trackmap.getTrackById(trackId)) {
      case null {
        Debug.print("Metadata not found");
        null};
      case (?track) {
        Debug.print("Metadata found");
        return ?track.getMetadata();
      };
    };
  };

  public shared query func getTrackList() : async [TR.Metadata] {
    let trackIter : Iter.Iter<Text> = trackmap.tracks.keys();
    var trackBuffer : Buffer.Buffer<TR.Metadata> = Buffer.Buffer<TR.Metadata>(0);
    for (trackId in trackIter) {
      Debug.print("Search Id " # trackId);
      switch (p_getMetadataById(trackId)) {
        case (null) {
          Debug.print("Metadata not found by caller - shall not happen");
        };
        case (?md) {
          trackBuffer.add(md);
        };
      };
    };
    return Buffer.toArray(trackBuffer);
  };

  public shared query func getTrackLineGeoJSON (trackId : Text) : async Text {
    switch (trackmap.getTrackById(trackId)) {
      case null {
        Debug.print("GeoJSON not found");
        "";
      };
      case (?track) {
        Debug.print("GeoJSON found");
        track.getGeoJSONLineFeature();
      };
    }
  };


  // all HTTP handling from motoko mailing list
  // Endpoints:
  // / : Landing Page - the service and the endpoint list
  // /conformance: static conformance page
  // /api: desribing the endpoints and the document structure
  // /collections: List of all collections/layers
  // /collections/{id}: Information on the collection 
  // /collections/{id}/items: Feature Collection
  // /collections/{id}/items/{featureid}: A single feature
  //
  // TODO: Filter BBOX, DateTime
  public shared query func http_request(request : http.HttpRequest) : async http.HttpResponse {  
    Debug.print("Function HttpRequest");
    //let baseURL = "dummy" # Principal.toText(Principal.fromActor(this));
    let urlPattern : http.URLPattern = http.parseURL(request);
    
    Debug.print(debug_show(urlPattern));
    // test the possible combinations
    // Root
    if (urlPattern.path.size() == 0) {
      return {
          status_code = 200;
          headers = [];
          body = Text.encodeUtf8(OR.getRootPage(trackmap,Principal.fromActor(this), dev, urlPattern.format));
          };
    };
    // Conformance
    if (urlPattern.path.size() == 1 and urlPattern.path[0] == "conformance") {
      return {
          status_code = 200;
          headers = [];
          body = Text.encodeUtf8(OCF.getConformancePage(urlPattern.format));
          };
    };   
    // Collections
    if (urlPattern.path.size() == 1 and urlPattern.path[0] == "collections") {
      return {
          status_code = 200;
          headers = [];
          body = Text.encodeUtf8(OC.getCollectionsPage(trackmap,Principal.fromActor(this), dev,urlPattern.format));
          };
    };
    // Single Collections
    if (urlPattern.path.size() == 2 and urlPattern.path[0] == "collections") {
      // Check the overall Feature Collection - hardcoded pattern
        if (urlPattern.path[1] == "FC") {
          return {
            status_code = 200;
            headers = [];
            body = Text.encodeUtf8(OCS.getCollectionsSingleMap (trackmap,Principal.fromActor(this), dev,urlPattern.format));
          };  
        };
        switch (trackmap.getTrackById(urlPattern.path[1])) {
          case (?(track)) {
            return {
              status_code = 200;
              headers = [];
              body = Text.encodeUtf8(OCS.getCollectionsSingleTrack(track,Principal.fromActor(this), dev,urlPattern.format));
            };
          };
          case _ {
            return {
              status_code = 404;
              headers = [];
              body = Text.encodeUtf8("No track found");
           };
          };
        }
    };    
    // Items
      if (urlPattern.path.size() == 3 and urlPattern.path[0] == "collections" and urlPattern.path[2] == "items") {
        // Check the overall Feature Collection - hardcoded pattern
        if (urlPattern.path[1] == "FC") {
          return {
            status_code = 200;
            headers = [];
            body = Text.encodeUtf8(OCSI.getCollectionsSingleMapItems(trackmap, Principal.fromActor(this), dev, urlPattern.format));
            // body = Text.encodeUtf8(trackmap.getGeoJSONLineCollection ());
          };  
        };
        switch (trackmap.getTrackById(urlPattern.path[1])) {
          case (?(track)) {
            return {
              status_code = 200;
              headers = [];
              body = Text.encodeUtf8(OCSI.getCollectionsSingleTrackItems(track, Principal.fromActor(this), dev, urlPattern.format));
              // body = Text.encodeUtf8(track.getGeoJSONPointCollection());
            };
          };
          case _ {
            return {
              status_code = 404;
              headers = [];
              body = Text.encodeUtf8("No track found");
           };
          };
        };      
    };


    switch ("/error") {
      case ("/") {
        return {
          status_code = 404;
          headers = [];
          body = Text.encodeUtf8("404 Errorpage");
          };
      };
      case ("/collections") {
        return {
          status_code = 200;
          headers = [];
          body = Text.encodeUtf8(OC.getCollectionsPage(trackmap, Principal.fromActor(this), dev, #json));
          };
      };
      // todo check the .../items
      case _ {
          return {
          status_code = 404;
          headers = [];
          body = Text.encodeUtf8("404 Errorpage");
          };
      };
    };
    ///
  };
}