# igc_managed - IGC Tracks to OGC API Features
# --- with user and canister management ---

## Previous work
In the previous project [IGC Tracks to OGC API Features](https://github.com/janschu/igc_tools) - a test scenario was set up to verify that an [OGC API Features](https://www.ogc.org/standard/ogcapi-features/) compliant server can be implemented as smart contract in the [Internet Computer](https://internetcomputer.org/) ecosystem. Static pages, [Motoko](https://internetcomputer.org/docs/current/motoko/main/motoko)  actors and dynamically created JSON and HTML were implented and tested to upload glider tracks ([International Gliding Commission file format](https://en.wikipedia.org/wiki/IGC_(file_format)), visualise them with web-mapping clients ([Leaflet](https://leafletjs.com/)) and user the standardised OGC API within a standard geographical information system (e.g. [QGIS](https://qgis.org/en/site/)).

## Implementation goal and use-case
In this project a potential use-case was implemented with focus on 'user-owned data and services'.

### Roles
Three potential roles were defined:
- The 'tool provider' (or a limited 'administrator'): This role runs a management page, offers the service to deploy new canisters with the service via an automated management page, but has no access to user data and cannot manipulate their services 


## Comments
- need to redesign - the project grew with new ideas - several spaghetti elements and redundant fragments (especially in the dynamic creation of the management page)
- need to optimise the requests and to cache content in frontend - too slow and too many requests

## Tools
- jsonHelper: (little) support in the dynamic creation of JSON elements
- htmlHelper: support in the creation of html tags (maybe useful for other projects)


