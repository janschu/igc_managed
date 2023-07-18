# Managed OGC API Features

## Previous work
In the previous project [IGC Tracks to OGC API Features](https://github.com/janschu/igc_tools) - a test scenario was set up to verify that an [OGC API Features](https://www.ogc.org/standard/ogcapi-features/) compliant server can be implemented as smart contract in the [Internet Computer](https://internetcomputer.org/) ecosystem. Static pages, [Motoko](https://internetcomputer.org/docs/current/motoko/main/motoko)  actors and dynamically created JSON and HTML were implented and tested to upload glider tracks ([International Gliding Commission file format](https://en.wikipedia.org/wiki/IGC_(file_format)), visualise them with web-mapping clients ([Leaflet](https://leafletjs.com/)) and user the standardised OGC API within a standard geographical information system (e.g. [QGIS](https://qgis.org/en/site/)).

## Implementation goal and use-case
In this project a potential use-case was implemented with focus on 'user-owned data and services'.

### Roles
Three potential roles were defined:
- The **'service provider'** (or a kind of 'administrator'): 
This role runs the management page, where registered users (role 'user') can obtain and initialize their personal OGC API Features compliant canister/server. The 'service provider' manages a list of users, that are allowed to create new canisters - because each canister needs to be 'precharged' with some money (or processing equivalents). The fresh canisters/servers run under full control of their owners - so the 'administrator' cannot manipulate any data and code of that service or even switch the canister on or off.
- The **'user'**:
The 'user' role describes a data owner, who wants to store his/her data on the blockchain and offer a standardized OGC API to access the data e.g. via a web or desktop GIS. The 'user' will use the general management page (that is maintained by the 'service provider') to initialize his/her canister. The canister is prcharched with some execution'fuel' - the recharging and maintenance (as far as required) must be managed by the 'user'. Some tools for the management can be accessed via the general management page - e.g. for uploading and deleting of data, or starting and stopping the service - or made directly using the http interface of the canister.
 


## Comments
- need to redesign - the project grew with new ideas - several spaghetti elements and redundant fragments (especially in the dynamic creation of the management page)
- need to optimise the requests and to cache content in frontend - too slow and too many requests

## Tools
- jsonHelper: (little) support in the dynamic creation of JSON elements
- htmlHelper: support in the creation of html tags (maybe useful for other projects)


