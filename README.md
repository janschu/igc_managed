# Managed OGC API Features

## Previous work
In the previous project [IGC Tracks to OGC API Features](https://github.com/janschu/igc_tools) - a test scenario was set up to verify that an [OGC API Features](https://www.ogc.org/standard/ogcapi-features/) compliant server can be implemented as smart contract in the [Internet Computer](https://internetcomputer.org/) ecosystem. Static pages, [Motoko](https://internetcomputer.org/docs/current/motoko/main/motoko)  actors and dynamically created JSON and HTML were implented and tested to upload glider tracks ([International Gliding Commission file format](https://en.wikipedia.org/wiki/IGC_(file_format)), visualise them with a web-mapping client ([Leaflet](https://leafletjs.com/)) and offer the standardised OGC API, so the data can be used within any standard geographical information system (e.g. [QGIS](https://qgis.org/en/site/)).

## Implementation goal and use-case
Whereas the [IGC Tracks to OGC API Features](https://github.com/janschu/igc_tools) mainly adresses the technical implementation, this project (extension) focusses on the ideas of **'user-owned data and services'**. A simple workflow (still dealing with IGC flight tracks) was designed to concentrate on data and service ownership within the [Internet Computer](https://internetcomputer.org/)(IC) ecosystem.

### Story
A glider pilot (data producer/data owner) tracks his/her flight with a GNSS based flight tracking system and wants to store it on the internet. Although there are very nice platforms available, the pilot does not feel comfortable about giving away the data to some platform operators, that might manipulate the data, change the terms of use, misuse it or even switch off their services. Furthermore the pilot likes to perform some spatial analysis about flight heights or tracks in combination with available weather data, so she/he needs to connect a geo-information-system via standard data interfaces.

Following those requirements, the user data and services shall run completely on a public blockchain application and only the creation of the according canisters and a simple catalog/data overview is managed central.

### Roles
- **Service provider** (or a kind of 'administrator'): 
This role runs the management page, where registered users (role 'user') can obtain and initialize their personal OGC API Features compliant canister/server. The 'service provider' manages a list of users, that are allowed to create new canisters - because each canister needs to be 'precharged' with some processing equivalents (fuel or in fact money). After their creation, the fresh canisters/servers run under full control of their owners and the 'administrator' cannot manipulate any data and code of that service or even cannot switch the canister on or off.
- **Data owner** (the glider pilot):
The 'data owner' role describes a user, who wants to store his/her data on the blockchain and offer a standardized OGC API to access the data e.g. via a web or desktop GIS. The 'data owner' will use the general management page (which is maintained by the 'service provider') to initialize his/her canister. The canister is precharged with some execution 'fuel' - the recharging and maintenance (as far as required) must be managed by the 'users' themselves. Some tools for the management can be accessed via the general management page - e.g. for the upload and delete of data, or to start and stopp the service. Alternativly those actions can also be made directly using the canister's API.
- **Guest** (anyone interested in glider data):
Also 'guests' shall use the system. On one hand any 'guest' can access the OGC API Features [^1] endpoints, as long as the according user canisters are running. This allows endusers (role 'guests') to directly work with the data of the providers (role 'user') without any intermediares. On the other hand, endusers/'guests' can also access the simple administration page to see all datasets from all registered and running canisters. The management page acts as 'catalog' system for all datasets.

[^1]: By default [OGC API Features](https://www.ogc.org/standard/ogcapi-features/) is open - without any access control

### Steps
1. The 'service provider' grants the 'data owner' the right to use the system by entering the principal (see [Internet Identity(https://identity.ic0.app/)]) of the 'data owner' and an initial amount of processing 'cycles' (see [cycles](https://internetcomputer.org/docs/current/concepts/tokens-cycles)) to the management page[^2].

[^2]: This registering process might support different business processes for the 'service provider' to cover development and maintenance cost of the source code as well as the initial setup and fueling of the canisters.

2. The 'data provider' logs in the management page by using the [Internet Identity(https://identity.ic0.app/)]. Only registerd users can perform the next steps 3 and 4.

3. The 'data owner' can now upload new IGC tracks. With the first upload of an IGC flight track, a new canister is created containing the application code for data parsing, storing and the OGC API Feautures. All rights are exclusivly granted to the 'data provider'. 

4. The 'data owner' can now use the management page to simplify the handling of data and his/her server, e.g. simpple buttons and links are included to 'start canister', 'stop canister', 'upload track' and 'delete track'. Furthermore, the canister specific linkts to the 'OGC API Features' endpoint and to the [Nervous Network System - main page](https://nns.ic0.app/accounts/) are provided.

5. 'Guest' use the management page as simple web mapping application. They can list the flight data of all 'data providers' and visualise the tracks. 

### Components

From a user's perspective, three relevant components are realised:

1. The canister that stores all flight data of one 'data owner', contain some public functions to upload, delete and retrieve data, and exposes the OGC API Features to access the data with any compliant software - e.g. QGIS desktop GIS or Leaflet web mapping library. The implementation is realised as Motoko 'Actor' (ogcActor.mo) and the sources can be found in the 'ogcAPI' package.

2. The 'management page', the frontend for 'guests' to list and view tracks of all 'data owners' on maps. The page also covers the ascects of managing data and canisters for the registered 'data owners'. The page is realised as single page app using bootstrap and Leaflet.

3. The management backend (main.mo) covers all business logic of the the frontend. This is on one hand the registration of users/'data owners' and the creation of new canisters. On the other hand it includes all the supportive functionalities for users/'data owners' and 'guests', like starting and stopping cansisters, adding and removing flight tracks as well as retrieve the relevant end-points of the OGC services.

## Implementation

### General design
The implementation consists of 2 main elements; the management part with frontend and backend, as well as the the user canisters that implement the OGC API Features.

- The **management part** is implemented as *standard* Internet Computer [Dapp](https://internetcomputer.org/docs/current/tutorials/create_your_first_app/). The frontend is using [Bootstrap](https://getbootstrap.com/) and ([Leaflet](https://leafletjs.com/)), the backend is implemented as Motoko actor. 
A relevant part - the creation of new canisters - mainly use ideas and parts from the blog entry of [David Dal Busco - Dynamically Create Canister Smart Contracts in Motoko](https://medium.com/dfinity/dynamically-create-canister-smart-contracts-in-motoko-d3b38a748c07). The integration of the Internet Identity within the frontend is based on the sample code and explanations of [Kyle Peacock - Integrating with Internet Identity](https://kyle-peacock.com/blog/dfinity/integrating-internet-identity/).

- The **OGC API** part is a plain [Motoko actor class](https://github.com/janschu/igc_managed/blob/master/src/lib/ogcAPI/ogcActor.mo). Beside some interfaces to be directly accessed from the management components, it mainly implements the function to process http/https requests, resolve the path patterns, the requested response formats and dispatch the request to according Motoko functions. There are several examples on the implementation e.g. the [motoko_http_handler](https://github.com/ORIGYN-SA/motoko_http_handler/tree/master). 

Additionally there are some helping modules and packages, which might be of interest for reuse

- [**jsonHelper**](https://github.com/janschu/igc_managed/blob/master/src/lib/helper/jsonHelper.mo): To implement OGC API Features we have to generate a lot of JSON/GeoJSON. To simplify those creation steps, a very limited module to generate KVP encodings or JSON links was written.

- [**htmlHelper**](https://github.com/janschu/igc_managed/blob/master/src/lib/helper/htmlHelper.mo): We also have to generate several dynamic html-pages (according to the OGC API specification). Beside general functions to create generic tags, attributes, text-nodes etc., there are also predefined common tags like *div* or *li* included. 

- [**igcData**](https://github.com/janschu/igc_managed/tree/master/src/lib/igcData): This package comprises some tools to parse [International Gliding Commission Tracks](https://www.fai.org/sites/default/files/igc_fr_specification_2020-11-25_with_al6.pdf) and keep the track data with metadata in a simplified datastructure [^3] .

[^3]: Note: Only the track data and some metadata are extracted. Advanced content like flight planning or the GNSS tracker's signature are ignored.

## Open issues

The project was **never intended to be productive**.
The main goal was to gain experiences and have a running demonstrator to further **elaborate potential use cases** of blockchain, smart contracts and Dapps in the **geospatial domain** [^4] .

[^4]: The project was presented and discussed at [FOSS4G 2023](https://2023.foss4g.org/)

**General comments**
- Complex html responses: The OGC API Features specification mainly describe two types of responses - the html and json responses. Therefore a lot of dynamically created html is needed to build correct responses. Without according libraries, this is quite complex
and took a lot of development effort [^5]

[^5]: The service description is very complex to design from scratch - so there is just a pointer to dummy (https://ogc-api.nrw.de/inspire-lc-zfum/v1/api?f=json) at the moment. Current clients only check the existence of this description.

**Issues**
- Lacking exception handling: There is only limited handling of exceptions - especially the IGC parsing relies on correct format.
- Redundant code fragments: Especially the 'management-page' contain some redundant part in retrieving lists of users, lists of canisters and tracks. 
- Sticky frontend: Too many calls to the management backend and the OGC API are made. This partly blocks the frontend and slows down the application. It might be useful to redesign the frontend code, bundle the requests to the backend - e.g. directly access the user-names and the list of datasets, instead of requesting the username from the principal, requesting the endpoint and then call the OGC API.  



