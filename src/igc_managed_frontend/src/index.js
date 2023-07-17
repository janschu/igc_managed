import { debug } from "util";
import { igc_managed_backend } from "../../declarations/igc_managed_backend";
import { AuthClient } from "@dfinity/auth-client";


const init = async () => {
  // to switch for local testing
  const testlocal = true;
  const iProvider = "http://127.0.0.1:4943/?canisterId=be2us-64aaa-aaaaa-qaabq-cai";
  // iProvider = "https://identity.ic0.app",

  var flightOverlay;


  // init auth
  const authClient = await AuthClient.create();

    // The relevant html elements
  const uploadForm = document.getElementById("uploadForm")
  const inputFileSelector = document.getElementById("inputFile");
  const submitButton = document.getElementById("submitButton");
  const messageBox = document.getElementById("message");
  const debugBox = document.getElementById("debug");
  const FileListElement = document.getElementById("fileId");
  var text = "";
  var flightMap;
  var flightOverlay;

  // login elements
  const loginButton = document.getElementById("loginButton");
    loginButton.addEventListener("click", login);
  const logoutButton = document.getElementById("logoutButton");
    logoutButton.addEventListener("click", logout);

  // User Info Elements
  const userInfoDiv = document.getElementById("userDiv");
  const userPrincipalBox = document.getElementById("userPrincipal");
  const userNameBox = document.getElementById("userName");
  const canInfoLink = document.getElementById("canisterInfo");
  const canEndpointLink = document.getElementById("canisterEnpoint");

  // Manage Container Elements
  const stopContainerButton = document.getElementById("stopContainer");
  stopContainerButton.addEventListener("click", stopContainer);
  const startContainerButton = document.getElementById("startContainer");
  startContainerButton.addEventListener("click", startContainer);

  // File Upload Form
  const uploadFormSection = document.getElementById("uploadForm");

  // const ogcAPILink = document.getElementById("LinkFeatureAPI");

  // login function using Internet Identity
  async function login () {
    await authClient.login ({
      onSuccess: async() => {messageBox.innerText = "Login Success";
                            checkAuthenticated();},
      onError: () => {messageBox.innerText = "LoginError"; 
                      checkAuthenticated();},
      // identityProvider: "https://identity.ic0.app",
      identityProvider: iProvider,
      maxTimeToLive: 3600000000000 //60 Minute
    });
    
  };

  // logout 
  async function logout () {
    await authClient.logout();
    checkAuthenticated();
  };

  // check Authenticated is used to update page after Login/Logoff
  async function checkAuthenticated() {
    const aut = await authClient.isAuthenticated();
    if (aut) {
      loginButton.disabled = true;
      logoutButton.disabled = false;
      // uploadFormSection.setAttribute("class", "d visible");
      // the container block
      setUserDiv(authClient.getIdentity().getPrincipal());
    } else {
      loginButton.disabled = false;
      logoutButton.disabled = true;   
      // uploadFormSection.setAttribute("class", "d invisible");
      setUserDiv(null); 
    }
    getTracklist();
  };

  async function setUserDiv(user) {
    try {
      const userelement = await igc_managed_backend.getUser(user);
      // if no error
      //userInfoDiv.className = "row bg-light rounded";
      userInfoDiv.className = "navbar navbar-expand-md navbar-light bg-light";
      // canInfoDiv.className = "row bg-light rounded";
      userPrincipalBox.innerText=user;
      userNameBox.innerText = userelement.username;  
      canEndpointLink.href = await igc_managed_backend.getOgcURL(user, "", {"html":null}, testlocal);
      canInfoLink.href = await igc_managed_backend.getIcpDashboard(user);
      await setCanisterStatus(user);  
      uploadFormSection.setAttribute("class", "d visible");
    }
    catch (error) {
      userInfoDiv.className = "d-none";
      uploadFormSection.setAttribute("class", "d invisible");
      debugBox.innerText= error;
      messageBox.innerText = "User is not registered: " + user;
      // switch off upload

    }
  }; 

  async function setCanisterStatus (user) {
    try {
      let state = await igc_managed_backend.getCanisterStatus(user);
      if (JSON.stringify(state) == JSON.stringify({"Running":null})) {
        startContainerButton.disabled = true;
        stopContainerButton.disabled = false;
        messageBox.innerText = "canister is running";
      } else {
        startContainerButton.disabled = false;
        stopContainerButton.disabled = true;        
        messageBox.innerText = "canister is stopped" ;
      }
    }
    catch (error) {
      debugBox.innerText = error;
    }
  };

  async function stopContainer (event) {
    messageBox.innerText = "Please wait - canister is stopping";
    let user = authClient.getIdentity().getPrincipal();
    await igc_managed_backend.stopCanister(user);
    setCanisterStatus(user);
    getTracklist(event);
  };

  async function startContainer (event) {
    messageBox.innerText = "Please wait - canister is starting";
    let user = authClient.getIdentity().getPrincipal();
    await igc_managed_backend.startCanister(user);
    setCanisterStatus(user);
    getTracklist(event);
  };




  // Handler on file input box 
  // Reading a text file
  // write content into debug box
  function handleFiles() {
    submitButton.setAttribute("disabled", true);
    var file = this.files[0]; 
    let reader = new FileReader();
    text = reader;
    reader.readAsText(file);

    // display the file text in debug box
    reader.onload = function() {
      text = reader.result;
      debugBox.innerText = text;
    };
    // Error handling
    reader.onerror = function() {
      debugBox.innerText = reader.error;
      console.log(reader.error);
    };

    submitButton.removeAttribute("disabled");
  }

  // Call the Main.mo
  async function uploadIGC (event) {
    // fresh check of identity
    let owner = authClient.getIdentity().getPrincipal();
    messageBox.innerText = "Uploading IGC file for owner: " + owner;
    event.preventDefault();
    submitButton.setAttribute("disabled", true);
    const message = await igc_managed_backend.uploadIGC(owner, text);
    submitButton.removeAttribute("disabled");
    messageBox.innerText = "IGC file upload completed";
    debugBox.innerText = message;
    getTracklist(event);
  };

  async function deleteTrackId (event) {
    var source = event.target || event.srcElement;
    var id = source.value;
     // fresh check of identity
     let owner = authClient.getIdentity().getPrincipal();  
     const message = await igc_managed_backend.deleteIGC(owner, id);
     debugBox.innerText = message;
     messageBox.innerText = "Track deleted";
     getTracklist();
  };

  async function getTrackAsLine(event){
    var source = event.target || event.srcElement;
    var link = source.value;
    // remove the old layer first
    if (flightOverlay) {
      flightMap.removeLayer(flightOverlay);
    }
    var geojsonMarkerOptions = {
      radius: 3,
      fillColor: "#ff7800",
      color: "#000",
      weight: 1,
      opacity: 1,
      fillOpacity: 0.8
  };

    (async () => {
      const flightData = await fetch(link, {
        headers: {
          'Accept': 'application/geo+json'
        }
      }).then(response => response.json());
      flightOverlay = L.geoJSON(flightData, 
        {pointToLayer: function (feature, latlng) {
          return L.circleMarker(latlng, geojsonMarkerOptions);},
        onEachFeature: function (f, l) {
          l.bindPopup('<pre>'+JSON.stringify(f.properties,null,' ').replace(/[\{\}"]/g,'')+'</pre>');
        }        
    },);
      flightMap.addLayer(flightOverlay);
      flightMap.fitBounds(flightOverlay.getBounds());
    })();
      
  };

  // Call Main.mo getTracklist
  async function getTracklist(event) {
    
    FileListElement.replaceChildren();

    let owner = authClient.getIdentity().getPrincipal();
    // handle the responses/exceptions
    const contId = igc_managed_backend.getOgcURL(owner, "/collections", {"json":null}, testlocal);
    contId.catch((error) => {
      debugBox.innerText= error;
      messageBox.innerText = "User cannot access tracks :" + owner;
      // reset the list
      // maybe switch to anonymous list
      
    });
    // In test environment 
    const url = await contId;
    messageBox.innerText = "Retrieve Data from OGC endpoint: " +  url;

    // fetch list of datasets
    const response = await fetch (url);
    const jsonResp = await response.json();
    const jsonColl = jsonResp["collections"];


    for (var item in jsonColl) {
      //debugBox.innerText = JSON.stringify(jsonColl[item]);
      const button = document.createElement("button");
      button.setAttribute("type", "button");
      button.setAttribute("class", "list-group-item list-group-item-action rounded");
      button.setAttribute("name", jsonColl[item].id);
      const contId = igc_managed_backend.getOgcURL(owner, "/collections/" + jsonColl[item].id + "/items", {"json":null}, testlocal);
      contId.catch((error) => {
        debugBox.innerText= error;
        messageBox.innerBox = "Error - shall not happen";
      });
      const url = await contId;
      button.setAttribute("value", url);
      button.setAttribute("class", "btn btn-outline-primary m-1 rounded col-9");
      FileListElement.appendChild(button);
      const subheading = document.createElement("div");
      subheading.setAttribute("class", "fw-bold");
      const subheadingText = document.createTextNode(jsonColl[item].title);
      subheading.appendChild(subheadingText);
      button.appendChild(subheading);
      const buttonText = document.createTextNode(jsonColl[item].description);
      //const buttonText = document.createTextNode(jsonColl[item].links[0].href);
      button.appendChild(buttonText);
      button.addEventListener("click",getTrackAsLine);

      const delButton = document.createElement("button");
      delButton.setAttribute("type", "button");
      delButton.setAttribute("class", "btn col-2 btn-outline-danger m-1");
      delButton.setAttribute("name", "delete");
      delButton.setAttribute("value", jsonColl[item].id);
      delButton.addEventListener("click", deleteTrackId);
      const delButtonText = document.createTextNode("Del");
      delButton.appendChild(delButtonText);

      const div = document.createElement("div");
      div.setAttribute("class", "row");
      div.appendChild(button);
      if (jsonColl[item].id!="FC") {
        div.appendChild(delButton);
      };

      FileListElement.appendChild(div);
    };
  };

  function initMap(event){
    flightMap = L.map('FlightMap');
    flightMap.setView([53.04229, 8.6335013],8, );
    var topPlusLayer = L.tileLayer.wms('http://sgx.geodatenzentrum.de/wms_topplus_open?', {format: 'image/png', layers: 'web', attribution: '&copy; <a href="http://www.bkg.bund.de">Bundesamt f&uuml;r Kartographie und Geod&auml;sie 2019</a>, <a href=" http://sg.geodatenzentrum.de/web_public/Datenquellen_TopPlus_Open.pdf">Datenquellen</a>'});
    var dgmLayer = L.tileLayer.wms('https://sgx.geodatenzentrum.de/wms_dgm200?', {format: 'image/png', layers: 'relief', attribution: '&copy; <a href="http://www.bkg.bund.de">GeoBasis-DE / BKG 2023</a>'});
    var sentinelLayer = L.tileLayer.wms('https://sgx.geodatenzentrum.de/wms_sen2europe?', {format: 'image/png', layers: 'rgb', attribution: '&copy; <a href="http://www.bkg.bund.de">Europäische Union, enthält Copernicus Sentinel-2 Daten 2023, verarbeitet durch das Bundesamt für Kartographie und Geodäsie (BKG) </a>'});
    var baseMaps = {
      "Top Plus": topPlusLayer,
      "Sentinel 2": sentinelLayer,
      "DEM": dgmLayer};
    var layerControl = L.control.layers(baseMaps).addTo(flightMap);
    topPlusLayer.addTo(flightMap);
  }

  inputFileSelector.addEventListener("change", handleFiles, false);
  uploadForm.addEventListener("submit", uploadIGC);
  checkAuthenticated();
  initMap();
  getTracklist();  

};

init();