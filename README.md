## Present Your Team

| Name                   |
| ---------------------- |
| Andhika Pangestu       |
| Benedict Kenjiro Lehot |
| Ivan Yuantama Pradipta |
| Ryan Safa Tjendana     |
| William Gozali         |

---

## Starting Assumption

_What did you assume, before any real exploration (start of investigation phase)? Be honest, including if your assumption is basically a guess. Write it and move on._

We think we'll end up using:

- MapKit for rendering the property map and displaying pins
- CoreLocation for capturing the user's GPS coordinates
- GeoToolbox for surfacing location details such as place names, Google Maps links, and nearby point-of-interest information at a tapped coordinate
- WeatherKit for capturing variables like temperature, humidity, etc
- FoundationModels to make a summary based on provided data. 

Because:
MapKit and CoreLocation are the standard Apple pairing for anything location based, so they felt like the obvious fit from the start. We assumed MapKit alone would not be enough to surface rich location metadata like formatted addresses and map links, so GeoToolbox seemed like a necessary addition. We use WeatherKit to get real time variable data so it can be more additional data. After fetching data, we want FoundationModels to generate a brief summary to be shown before each detailed data. 

---

## The Exploration Log

_Not your conclusion, your actual process. Update this as you go, it doesn't need to be written in one sitting._

**What we browsed, and what surprised us:**

- We explored MapKit's `MKCoordinateRegion` and `MKMapView` to understand how to center the map on a live coordinate. The setup was straightforward.
- We looked for reverse geocoding and find that with `CLGeocoder`, we can implement that.
- We discovered `MKMapItem` can generate more details than `GeoToolBox` for pin location. So we decide to use only `MKMapItem` for our app.

**What we actually built or tested in code:**

- A `LocationManager` class using `CLLocationManager` with `requestWhenInUseAuthorization()` that publishes the live coordinate via `@Published` for SwiftUI binding.
- An `MKCoordinateRegion` binding that re-centers the map whenever the user's coordinate updates.
- A reverse geocoding flow using `CLGeocoder.reverseGeocodeLocation()` that populates a detail card with a formatted address and a Maps link via `MKMapItem`.
- A WeatherModel class using `WeatherService.shared.weather(for:)` that fetches current temperature, humidity, precipitation, and UV index for the selected coordinate, requiring the WeatherKit capability to be activated on an Apple Developer account.
- A `LanguageModelSession` class from `FoundationModels` to make a summary with a sets of `instruction`.
- A PostGIS + Express.js backend (`/api/analyze`) returning raw property's risk data for any coordinate, The data contain like flood zones, air quality, temperature, elevation, population density, green spaces, road access, public facilities, internet connectivity, and crime statistics.

**What we discovered that we didn't expect:**

- Supabase free tier no longer exposes a direct PostgreSQL connection for new projects, routing all traffic through PgBouncer in transaction pooling mode. This caused abnormally high query planning times and overall API response times of 8–10 seconds.
- Migrating the database to Neon resolved the direct connection issue and brought API response time down to under 2 seconds.
- The `FoundationModels` still not provide model for Bahasa Indonesia. 

---

## What We Tried and Dropped

_Name at least one real alternative you seriously considered, and explain why it got cut._

**We considered:**
Using `GeoToolBox` as the primary framework for surfacing location details at a tapped coordinate, such as place names, formatted addresses, Google Maps links, etc.

**We dropped it because:**
After exploring MapKit more thoroughly, we found that `MKMapItem` already provides a complete point description including place name, address, and a direct deep link to Apple Maps with no external dependency required.


**We considered:**
Keeping Supabase as the long term database host, since it was already in use during early development.

**We dropped it because:**
Supabase free tier removed direct PostgreSQL connections for new projects, forcing all traffic through PgBouncer in transaction pooling mode. This disabled prepared statement caching and inflated query planning time from the expected ~2ms to ~48ms per query, making the API too slow for our app loading. We migrated to NeonDB, which provides direct connections and full PostGIS support on the free tier.


**We considered:**
Using `FoundationModels` to make a summary. 

**We dropped it because:**
We tried the `FoundationModels`, but it only works when our device (Iphone 17) is using English as it's general system languange. From what we found, `FoundationModels` has several language it currently support, but Indonesia wasn't on the list. We did tried with several other language on the list as our general system language, but the model also didn't work. For as long as we've tested, the `FoundationModels` only work when the general system language is English. We then thought to only use this model when the device language is English and replace it with a template when other language is used, but then we come to a sense like "Why not just use a template for every device language and not use an AI model to make a summary?"

---

## Real Limitations Hit

**Situation 1: Supabase pooler inflating PostGIS planning time**

The `/api/analyze` endpoint was consistently taking 8–10 seconds per request even with GIST spatial indexes on all geometry columns. Running `EXPLAIN ANALYZE` revealed query planning time of ~48ms per query, far above the normal 1–5ms, caused by PgBouncer's transaction pooling mode preventing statistics caching between connections.

How we worked around it:
We migrated the database from Supabase to Neon, which supports direct PostgreSQL connections on the free tier. Planning time dropped to normal levels and total API response time improved significantly.

---

## The Revised Decision

**Final decision:**

- **CoreLocation**: live GPS coordinate capture via Location Manager, and address resolution via CLGeocoder (Reverse Geocoding)
- **MapKit**: map rendering and Coordinate Region centering
- **WeatherKit**: for giving additional variabel data to make our app more detail.

**What changed since Section 1, and why:**

The CoreLocation and MapKit pairing held exactly as assumed, and CLGeocoder (which was already part of CoreLocation) proved even easier to integrate than expected.

---

## App Track Addendum

### About the Frameworks

All three frameworks are genuinely necessary and work together in sequence. CoreLocation provides the coordinate and resolves the address, MapKit consumes that coordinate to render the map and display the surrounding area, WeatherKit consumes that same coordinate to fetch real-time environmental variables (temperature, humidity, precipitation, UV index) that enrich the property overview with live conditions rather than static data alone. Removing any one of them degrades the core use case: without CoreLocation there is no coordinate or address, without MapKit there is no spatial context, and without WeatherKit the property overview is limited to static risk data with no live environmental signal.

The challenge response reflects this: _Create an app that utilizes Location Manager for location tracking, Reverse Geocoding for address resolution, Coordinate Regions for map navigation, and WeatherService to to fetch and present environmental conditions data for any selected property._

### About Accessibility and Localization

We localized the app in two languages: `English` and `Bahasa Indonesia`. The target users for this app is Indonesian people who want buy property and tourism people who want rent property, so supporting both languages ensures the app is accessible to the full audience.

### About Privacy

The app requests a single permission: `NSLocationWhenInUseUsageDescription`, which allows location access only while the app is in the foreground. No location data is stored on-device or transmitted beyond the coordinate sent to our own backend API for spatial analysis.

If the user denies location permission, the map defaults to a region centered on Bali and the "analyze current location" button is disabled. A card is shown to guide the user to enable location access in Settings. Everything else in the app still works normally.
