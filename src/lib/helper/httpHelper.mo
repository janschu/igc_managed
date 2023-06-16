import H "helper";
import Buffer "mo:base/Buffer";
import Array "mo:base/Array";
import Debug "mo:base/Debug";
import Iter "mo:base/Iter";
import Text "mo:base/Text";
import Bool "mo:base/Bool";
import Principal "mo:base/Principal";

module {
    public type KVP = (Text, Text);

    public func buildUrl (path: Text, canister: Principal, local: Bool, format: H.Representation) : Text {
      var url : Text = "";
      if local {
        url #= "http://127.0.0.1:4943" # path # "?canisterId=" # Principal.toText(canister) # "&"; 
      } else {
        url #= "https://" # Principal.toText(canister) # ".raw.icp0.io" # path # "?";
      };
      switch (format) {
        case (#json) {
          url #= "f=json";
        };
        case (#html) {
          url #= "f=html";
        };
        case (_) {
          url #= "f=json"; // default
        };
      };
      return url;
    };

    public type HttpRequest = {
        method : Text;
        url : Text;
        headers : [KVP];
        body : Blob;
    };

  public type HttpResponse = {
        status_code : Nat16;
        headers : [KVP];
        body : Blob;
    };
  
  public type URLPattern = {
        path : [Text];
        queryParams : [(Text,Text)];
        format : H.Representation;
    };

  public func parseURL (request : HttpRequest) : URLPattern {
    Debug.print("Function: parseURL");
    Debug.print("Request Method: " # request.method);
    Debug.print("Request URL" # request.url);
    Debug.print("Request Headers" # debug_show(request.headers));
    Debug.print("Request Body" # debug_show(request.body));
    // split path and queryParams -> result shall be of size 1 or 2
    let urlparts : [Text] = Iter.toArray(Text.tokens(request.url, #char '?'));
    // split path components
    let pathComponents : [Text] = Iter.toArray(Text.tokens(urlparts[0], #char '/'));
    // split query elements
    var kvpBuffer : Buffer.Buffer <(Text,Text)> = Buffer.Buffer <(Text,Text)> (0);
    if (urlparts.size() > 1) {
      let queryIter : Iter.Iter<Text> = Text.split(urlparts[1], #char '&');
      // split KVP 
      Iter.iterate<Text>(queryIter, func (item, _index) {
        let kvp: [Text] = Iter.toArray(Text.split(item, #char '='));
        kvpBuffer.add((kvp[0],kvp[1]));
      });
    };
    let qp : [(Text, Text)] = Buffer.toArray(kvpBuffer);
    // Check the requested format - query param with higher priority
    var rf : H.Representation = getResponseFormatQuery(qp);
    if (rf == #undefined) {
      rf := getResponseFormatHeader (request.headers);
    };
    return {
      path = pathComponents;
      queryParams = qp;
      format = rf;
    };
  };

  public func getResponseFormatQuery (queryParams: [(Text, Text)]): H.Representation {
    let format : ?(Text,Text) = Array.find<(Text,Text)>(queryParams, func (x) {x.0 =="f"});
    switch format {
      case (?pair) {
        if (pair.1=="html" or pair.1=="HTML") {return #html} 
        else if (pair.1=="json" or pair.1=="JSON") {return #json}
        else return #undefined;
      };
      case (_) {
        return #undefined;
      };
    };
  };

  public func getResponseFormatHeader(requestHeaders: [KVP]): H.Representation {
    let format : ?KVP = Array.find<KVP>(requestHeaders, func (x) {x.0 == "accept"});
    switch format {
      case (?pair) {
        if (Text.contains(pair.1,#text("application/json"))){return #json}
        else if (Text.contains(pair.1,#text("text/html"))){return #html}
        else return #undefined;
      };
      case (_) {
        return #undefined;
      };
    };
  };
};
