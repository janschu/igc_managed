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

[^1]: In general the [OGC API Features](https://www.ogc.org/standard/ogcapi-features/) do not define access control

### Steps


## Comments
- need to redesign - the project grew with new ideas - several spaghetti elements and redundant fragments (especially in the dynamic creation of the management page)
- need to optimise the requests and to cache content in frontend - too slow and too many requests

## Tools
- jsonHelper: (little) support in the dynamic creation of JSON elements
- htmlHelper: support in the creation of html tags (maybe useful for other projects)


