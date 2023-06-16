import { igc_managed_backend } from "../../declarations/igc_managed_backend";
import { AuthClient } from "@dfinity/auth-client";


const init = async () => {
  const testlocal = true;

  var flightOverlay;

  // init auth
  const authClient = await AuthClient.create();
  // login elements
  const loginButton = document.getElementById("loginButton");
  loginButton.addEventListener("click", login);
  const logoutButton = document.getElementById("logoutButton");
  logoutButton.addEventListener("click", logout);
  const userBox = document.getElementById("userPrincipal");
  const ogcAPILink = document.getElementById("LinkFeatureAPI");

  // login function using Internet Identity
  async function login () {
    await authClient.login ({
      onSuccess: async() => {},
      onError: () => messageBox.innerText = "LoginError",
      // identityProvider: "https://identity.ic0.app",
      maxTimeToLive: 3600000000000 //60 Minute
    });
    checkAuthenticated();
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
      userBox.innerText = "Principal: " + authClient.getIdentity().getPrincipal();
    } else {
      loginButton.disabled = false;
      logoutButton.disabled = true;
      userBox.innerText = "not logged in";     
    }
    // set the correct link to feature API
    const contId = igc_managed_backend.getOgcURL(authClient.getIdentity().getPrincipal(), "", {"html":null}, testlocal);
    contId.catch((error) => {
      messageBox.innerText= error;
    });
    // In test environment 
    ogcAPILink.href = await contId;
  };


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
    messageBox.innerText = owner;
    event.preventDefault();
    submitButton.setAttribute("disabled", true);
    const message = await igc_managed_backend.uploadIGC(owner, text);
    submitButton.removeAttribute("disabled");
    messageBox.innerText = message;
    getTracklist(event);
  };

  async function deleteTrackId (event) {
    var source = event.target || event.srcElement;
    var id = source.value;
     // fresh check of identity
     let owner = authClient.getIdentity().getPrincipal();  
     const message = await igc_managed_backend.deleteIGC(owner, id);
     //messageBox.innerText = message;
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
    let owner = authClient.getIdentity().getPrincipal();
    // handle the responses/exceptions
    const contId = igc_managed_backend.getOgcURL(owner, "/collections", {"json":null}, testlocal);
    contId.catch((error) => {
      messageBox.innerText= error;
    });
    // In test environment 
    const url = await contId;
    messageBox.innerText = url;

    // fetch list of datasets
    const response = await fetch (url);
    const jsonResp = await response.json();
    const jsonColl = jsonResp["collections"];

    FileListElement.replaceChildren();

    for (var item in jsonColl) {
      //debugBox.innerText = JSON.stringify(jsonColl[item]);
      const button = document.createElement("button");
      button.setAttribute("type", "button");
      button.setAttribute("class", "list-group-item list-group-item-action rounded");
      button.setAttribute("name", jsonColl[item].id);
      const contId = igc_managed_backend.getOgcURL(owner, "/collections/" + jsonColl[item].id + "/items", {"json":null}, testlocal);
      contId.catch((error) => {
        messageBox.innerText= error;
      });
      const url = await contId;
      button.setAttribute("value", url);
      button.setAttribute("class", "rounded col-9");
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
      delButton.setAttribute("class", "btn col-2 btn-danger");
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
    topPlusLayer.addTo(flightMap);
  }

  inputFileSelector.addEventListener("change", handleFiles, false);
  uploadForm.addEventListener("submit", uploadIGC);
  checkAuthenticated();
  initMap();
  getTracklist();  
  // document.addEventListener('DOMContentLoaded', initMap);
  // document.addEventListener('DOMContentLoaded', getTracklist);

};

init();