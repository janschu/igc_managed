import F "mo:base/Float";

import TM "../igcData/igcTrackMap";
import TR "../igcData/igcTrack";
import OC "ogcApiCollections";
import H "../helper/helper";
import DT "../helper/dateTime";
import HTML "../helper/htmlHelper";
import HTTP "../helper/httpHelper";
import BBox "../helper/BBox";


module {

    // The complete Map as FC
    public func getCollectionsSingleMap (map: TM.TrackMap, canister: Principal, local: Bool, repr: H.Representation ): Text {
        if (repr == #json) {
            return getCollectionsSingleMapJSON(map, canister, local);
        };
        return getCollectionsSingleMapHTML(map, canister, local);
    };

    private func getCollectionsSingleMapJSON (map: TM.TrackMap, canister: Principal, local: Bool) : Text {
        OC.apiJSONCollectionTrack (map, canister, local);
    };


    private func getCollectionsSingleMapHTML (map: TM.TrackMap, canister: Principal, local: Bool) : Text {
        return htmlSkeletonCollection(map.getBBox(), "FC", canister, local);       
    };


    public func getCollectionsSingleTrack (track: TR.Track, canister: Principal, local: Bool, repr: H.Representation ): Text {
        if (repr == #json) {
            return getCollectionsSingleTrackJSON(track, canister, local);
        };
        return getCollectionsSingleTrackHTML(track, canister, local);
    };

    private func getCollectionsSingleTrackJSON (track: TR.Track, canister: Principal, local: Bool) : Text {
        OC.apiJSONTrack(track, canister, local); 
    };

    private func getCollectionsSingleTrackHTML (track: TR.Track, canister: Principal, local: Bool) : Text {
        return htmlSkeletonCollection(track.getBBox(), track.getTrackId(), canister, local);
    };

    // Helper for HTML Skeleton
    // Genetates the page with a JSON and the ID
    private func htmlSkeletonCollection (extent: BBox.BBox, collectionID : Text, canister: Principal, local: Bool) : Text {
       // head
        var head : Text = HTML.create_MetaCharset("utf-8");
        head #= HTML.create_MetaNameContent("viewport","width=device-width, initial-scale=1" );
        head #= HTML.create_Link("stylesheet", "https://cdn.simplecss.org/simple.min.css");
        // Leaflet
        head #= HTML.create_Link("stylesheet", "https://unpkg.com/leaflet@1.9.2/dist/leaflet.css"); // integrity and crossorigin?
        head #= HTML.create_Script(null,?"https://unpkg.com/leaflet@1.9.2/dist/leaflet.js");
        // Init Leaflet - this is ugly
        var mapScript : Text = "function initMap(event){";
        mapScript #= "var flightMap = L.map('FlightMap');";
        //mapScript #= "flightMap.setView([53.04229, 8.6335013],10, );";
        mapScript #= "flightMap.fitBounds([[" # F.toText(extent.minLat) # ", " # F.toText(extent.minLon) # "], [" # F.toText(extent.maxLat) # "," # F.toText(extent.maxLon) # "]]);";
        mapScript #= "var topPlusLayer = L.tileLayer.wms('http://sgx.geodatenzentrum.de/wms_topplus_open?',";
        mapScript #= " {format: 'image/png', layers: 'web',";
        mapScript #= " attribution: '&copy; Bundesamt f&uuml;r Kartographie und Geod&auml;sie 2019'});";
        mapScript #= " topPlusLayer.addTo(flightMap);";

        // Get the flights
        mapScript #= "var flightFeatures = ";
        //mapScript #= getCollectionsSingleMapJSON (map: TM.TrackMap, baseURL: Text) # ";";
        mapScript #= getBBoxJSONFeature(extent) # ";";
        mapScript #= "L.geoJSON(flightFeatures).addTo(flightMap);";

        mapScript #= "};";
        mapScript #= "document.addEventListener('DOMContentLoaded', initMap);";

        head #= HTML.create_Script(?mapScript,null);
        // Style Setting just for the map
        var mapStyle : Text = "div#FlightMap { min-height: 500px;}";
        head #= HTML.create_Style(mapStyle);

        // body
        // - - Header Parts
        var headerContent :Text = "";
        // - - - Nav
        var navContent : Text = "";
        navContent #= HTML.create_A("Landing", HTTP.buildUrl("", canister, local, #html), null, ?"current");
        navContent #= HTML.create_A("Collections", HTTP.buildUrl("/collections", canister, local, #html), null, null);
        navContent #= HTML.create_A("Service Description", "https://m2ifq-raaaa-aaaah-abtla-cai.ic0.app/openapi.html", null, null);
        navContent #= HTML.create_A("Conformance", HTTP.buildUrl("/conformance", canister, local, #html), null, null);
        navContent #= HTML.create_A("Items", HTTP.buildUrl("/collections/" # collectionID # "/items", canister, local, #html), null, null);

        navContent #= HTML.create_A("JSON", HTTP.buildUrl("/collections/" # collectionID, canister, local, #json), null, ?"JSON");
        // - - Header
        headerContent #= HTML.create_Nav(navContent,null,null);
        headerContent #= HTML.create_H1("Data Page for Feature Collection", null, null);
        headerContent #= HTML.create_Div("All Flights in one Feature Collection", null, null);
         // Main
        var mainContent : Text = "";
        mainContent #= HTML.create_H1("Item Map", null, null);

        mainContent #= HTML.create_Div("", ?"FlightMap", null);

        // Main
        mainContent #= HTML.create_H1("Links:", null, null);
        // Link to collection page
        mainContent #= HTML.create_H2("Items Page", null, null);
        mainContent #= HTML.create_H3(
            HTML.create_A("Items HTML", HTTP.buildUrl("/collections/" # collectionID # "/items", canister, local, #html), null, null),null,null);
        mainContent #= HTML.create_Div("Data for the Feature Collection - as HTML",null, null);
        mainContent #= HTML.create_H3(
            HTML.create_A("Items JSON", HTTP.buildUrl("/collections/" # collectionID # "/items", canister, local, #json), null, null),null,null);
        mainContent #= HTML.create_Div("Data for the Feature Collection - JSON for GIS applications",null, null);  

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

    public func getBBoxJSONFeature (box : BBox.BBox) : Text {
        var jsonFeature : Text = "{\"type\": \"Feature\", \"properties\": {";
        jsonFeature #= "}, \"geometry\": ";
        jsonFeature #= "{\"coordinates\": [";
        jsonFeature #= "[";
        jsonFeature #= "[" # F.toText(box.minLon) # "," # F.toText(box.minLat) # "]";
        jsonFeature #= ",";
        jsonFeature #= "[" # F.toText(box.minLon) # "," # F.toText(box.maxLat) # "]";
        jsonFeature #= ",";
        jsonFeature #= "[" # F.toText(box.maxLon) # "," # F.toText(box.maxLat) # "]";
        jsonFeature #= ",";
        jsonFeature #= "[" # F.toText(box.maxLon) # "," # F.toText(box.minLat) # "]";
        jsonFeature #= ",";
        jsonFeature #= "[" # F.toText(box.minLon) # "," # F.toText(box.minLat) # "]";
        jsonFeature #= "]";
        jsonFeature #= "], \"type\": \"Polygon\"";
        jsonFeature #= "}";
        jsonFeature #= "}";

        return jsonFeature;
    };
};
