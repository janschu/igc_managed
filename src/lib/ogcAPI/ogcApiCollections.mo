import C "mo:base/Char";
import I "mo:base/Iter";
import N "mo:base/Nat";

import TM "../igcData/igcTrackMap";
import TR "../igcData/igcTrack";
import H "../helper/helper";
import JH "../helper/jsonHelper";
import DT "../helper/dateTime";
import HTML "../helper/htmlHelper";
import HTTP "../helper/httpHelper";
import BBox "../helper/BBox";
import Bool "mo:base/Bool";
import Prelude "mo:base/Prelude";

module {

    public func getCollectionsPage (map: TM.TrackMap, canister: Principal, local: Bool, repr: H.Representation ): Text {
        if (repr == #json) {
            return getCollectionsJSON(map, canister: Principal, local: Bool);
        };
        return getCollectionsHTML(map, canister: Principal, local: Bool);
    };


    private func getCollectionsJSON (map: TM.TrackMap, canister: Principal, local: Bool) : Text {
        // Open
        var body : Text = "{" # JH.lb();
        // Links
        body #= "\"links\": " # "[" # JH.lb();
        body #=JH.linkJSON("self", "application/json", "This document as JSON", HTTP.buildUrl("/collections", canister, local, #json));
        body #=","#JH.lb();
        body #=JH.linkJSON("alternate", "text/html", "This document as HTML",  HTTP.buildUrl("/collections", canister, local, #html));
        body #= "]"# JH.lb();
        body #=","#JH.lb();
        body #= "\"collections\": ["# JH.lb();
        // all tracks as one FC
        // the complete collection as one 'Track'
        body #= apiJSONCollectionTrack (map : TM.TrackMap, canister: Principal, local: Bool);
        body #= ","# JH.lb();

        // each Track as Point FC
        // each Track as Line FC
        let iterTracks : I.Iter<TR.Track> = map.tracks.vals();
        I.iterate<TR.Track>(iterTracks, func(track, _index) {
            body #= apiJSONTrack(track,canister, local);
            if (_index+1 < map.tracks.size()){
                body #= ",";
            };
            body #= JH.lb();
        });

        body #= "]"# JH.lb();
        // Close
        body #= "}";

        return body; 
    };

    public func apiJSONTrack (track : TR.Track, canister: Principal, local: Bool) : Text {
        let metadata : TR.Metadata = track.getMetadata();
        var text : Text = "{" # JH.lb();

        text #= JH.optKvpJSON("title",?("Flight: " # H.optionalText(metadata.gliderId) # " " # H.optionalText(metadata.start)),true);
        text #= JH.optKvpJSON("description",?("FlightLog: " # "Glider : " # H.optionalText(metadata.gliderId) # " Start: " # H.optionalText(metadata.start)),true);
        text #= JH.optKvpJSON("id",?(metadata.trackId),true);
        text #= "\"keywords\": " # JH.textArrayJSON(["Flight", "Track", H.optionalText(metadata.gliderId), H.optionalText(metadata.gliderPilot), H.optionalText(metadata.competitionId)]) # "," # JH.lb();
        text #= "\"isDataset\": true";
        text #= "," # JH.lb();
        text #= "\"type\": \"FeatureCollection\"";  
        text #= "," # JH.lb();
        text #= "\"extent\": {" #JH.lb();
        text #= JH.spatialExtentJson(metadata.bbox);
        text #= "," # JH.lb();
        text #= JH.temporalExtentJson( metadata.start, metadata.land);
        text #= JH.lb();
        text #= "} ," # JH.lb();
        text #= "\"links\": [" # JH.lb();
        text #=JH.linkJSON("self", "application/json", "This document as JSON", HTTP.buildUrl("/collections/" # metadata.trackId, canister, local, #json));
        text #=","#JH.lb();
        text #=JH.linkJSON("alternate", "text/html", "This document as HTML", HTTP.buildUrl("/collections/" # metadata.trackId, canister, local, #html));
        text #=","#JH.lb();
        text #=JH.linkJSON("items", "application/geo+json", "The items as GeoJSON", HTTP.buildUrl("/collections/" # metadata.trackId # "/items", canister, local, #json));
        text #=","#JH.lb();
        text #=JH.linkJSON("items", "text/html", "The items as HTML", HTTP.buildUrl("/collections/" # metadata.trackId # "/items", canister, local, #html));
        text #= "] " # JH.lb();
        // close 
        text #= "}";
        return text;
    };

    public func apiJSONCollectionTrack (map : TM.TrackMap, canister: Principal, local: Bool) : Text { 
        var text : Text = "{" # JH.lb();
        text #= JH.optKvpJSON("title",? map.metadata.title,true);
        text #= JH.optKvpJSON("description",?(map.metadata.description),true);
        text #= JH.optKvpJSON("id",?(map.metadata.id),true);
        text #= "\"keywords\": " # JH.textArrayJSON(["Collection", "Glider", "Flights"]) # "," # JH.lb();
        text #= "\"isDataset\": true";
        text #= "," # JH.lb();
        text #= "\"type\": \"FeatureCollection\"";  
        text #= "," # JH.lb();
        text #= "\"extent\": {" #JH.lb();
        text #= JH.spatialExtentJson(map.metadata.bbox);
        text #= "," # JH.lb();
        text #= JH.temporalExtentJson(? DT.prettyDateTime(map.metadata.start), ? DT.prettyDateTime(map.metadata.land));
        text #= JH.lb();
        text #= "} ," # JH.lb();
        text #= "\"links\": [" # JH.lb();
        text #=JH.linkJSON("self", "application/json", "This document as JSON", HTTP.buildUrl("/collections/" # map.metadata.id, canister, local, #json));
        text #=","#JH.lb();
        text #=JH.linkJSON("alternate", "text/html", "This document as HTML", HTTP.buildUrl("/collections/" # map.metadata.id, canister, local, #html));
        text #=","#JH.lb();
        text #=JH.linkJSON("items", "application/geo+json", "The items as GeoJSON", HTTP.buildUrl("/collections/" # map.metadata.id # "/items", canister, local, #json));
        text #=","#JH.lb();
        text #=JH.linkJSON("items", "text/html", "The items as HTML", HTTP.buildUrl("/collections/" # map.metadata.id # "/items", canister, local, #html));
        text #= "] " # JH.lb();
        // close 
        text #= "}";
        return text;
    };

    // TODO Check path
    private func getCollectionsHTML (map: TM.TrackMap, canister: Principal, local: Bool) : Text {
        // head
        var head : Text = HTML.create_MetaCharset("utf-8");
        head #= HTML.create_MetaNameContent("viewport","width=device-width, initial-scale=1" );
        head #= HTML.create_Link("stylesheet", "https://cdn.simplecss.org/simple.min.css");

        // body
        // - - Header Parts
        var headerContent :Text = "";
        // - - - Nav
        var navContent : Text = "";
        navContent #= HTML.create_A("Landing", HTTP.buildUrl("", canister, local, #html), null, ?"current");
        navContent #= HTML.create_A("Collections", HTTP.buildUrl("/collections", canister, local, #html), null, ?"current");
        navContent #= HTML.create_A("Service Description", "https://m2ifq-raaaa-aaaah-abtla-cai.ic0.app/openapi.html", null, null);
        navContent #= HTML.create_A("Conformance", HTTP.buildUrl("/conformance", canister, local, #html), null, null);
    
        navContent #= HTML.create_A("JSON", HTTP.buildUrl("/collections", canister, local, #json), null, ?"JSON");
        // - - Header
        headerContent #= HTML.create_Nav(navContent,null,null);
        headerContent #= HTML.create_H1("API Collection Page", null, null);
        headerContent #= HTML.create_Div("Listing the available data/feature collections", null, null);
         // Main
        var mainContent : Text = "";
        mainContent #= HTML.create_H1("Data", null, null);

        // all flights as one collection
        mainContent #= apiHTMLCollectionTrack (map, canister, local);
                        
        // each flight        
        let iterTracks : I.Iter<TR.Track> = map.tracks.vals();
        I.iterate<TR.Track>(iterTracks, func(track, _index) {
            mainContent #= apiHTMLTrack(track, canister, local);
        });

        // other links
        // mainContent #= HTML.create_H1("Other Links", null, null);
                
        // Footer
        var footerContent : Text = "";
        footerContent #= HTML.create_Div("Test for OGC on IC", null, null);
        
        // Body
        var body :Text = "";
        body #= HTML.create_Header(headerContent, null, null);
        body #= HTML.create_Main(mainContent, null, null);
        body #= HTML.create_Footer(footerContent, null, null);
        
        return HTML.createPage(?head,?body);
    };

    public func apiHTMLTrack (track : TR.Track, canister: Principal, local: Bool) : Text {
        let metadata : TR.Metadata = track.getMetadata();
        var text : Text = "";

        var link : Text = HTML.create_H2(H.optionalText(metadata.gliderId) # " " # H.optionalText(metadata.start), null, null);
        text #= HTML.create_A(link, HTTP.buildUrl("/collections/" # metadata.trackId, canister, local, #html), null, null);

        var id_div : Text = "";
        link := HTML.create_Div("id: " # metadata.trackId # " (html)",null, null);
        id_div #= HTML.create_A(link, HTTP.buildUrl("/collections/" # metadata.trackId, canister, local, #html), null, null);

        link := HTML.create_Div("id: " # metadata.trackId # " (json)",null, null);
        id_div #= HTML.create_A(link, HTTP.buildUrl("/collections/" # metadata.trackId, canister, local, #json), null, null);
        text #= HTML.create_Div(id_div, null, null);
        switch (metadata.gliderId) {
            case(?gid) {
                text #= HTML.create_Div("glider: " # gid ,null, null);
            };
            case (_) {
                text #= HTML.create_Div("glider: unknown" ,null, null);
            };
        };
        switch (metadata.start) {
            case(?st) {
                text #= HTML.create_Div("start: " # st, null, null);
            };
            case (_) {
                text #= HTML.create_Div("start: unknonw", null, null);
            };
        };
        switch (metadata.land) {
            case(?l) {
                text #= HTML.create_Div("land: " # l, null, null);
            };
            case (_) {
                text #= HTML.create_Div("land: unknonw", null, null);
            };
        };
        return text;
    };

    public func apiHTMLCollectionTrack (map : TM.TrackMap, canister: Principal, local: Bool) : Text {
        var text : Text = "";

        var link : Text = HTML.create_H2(map.metadata.title, null, null);
        text #= HTML.create_A(link, HTTP.buildUrl("/collections/" # map.metadata.id , canister, local, #html), null, null);

        var id_div : Text = "";
        link := HTML.create_Div("id: " # map.metadata.id # " (html)",null, null);
        id_div #= HTML.create_A(link, HTTP.buildUrl("/collections/" # map.metadata.id , canister, local, #html), null, null);

        link := HTML.create_Div("id: " # map.metadata.id # " (json)",null, null);
        id_div #= HTML.create_A(link, HTTP.buildUrl("/collections/" # map.metadata.id , canister, local, #json), null, null);
        text #= HTML.create_Div(id_div, null, null);

        text #= HTML.create_Div("glider: all gliders in one collection" ,null, null);

        text #= HTML.create_Div("start: " # DT.prettyDateTime(map.metadata.start), null, null);
        text #= HTML.create_Div("land: " # DT.prettyDateTime(map.metadata.land), null, null);
        return text;
    };    
};