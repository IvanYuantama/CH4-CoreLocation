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
- An external AI API (such as OpenAI) for generating a property risk summary

Because:
MapKit and CoreLocation are the standard Apple pairing for anything location based, so they felt like the obvious fit from the start. We assumed MapKit alone would not be enough to surface rich location metadata like formatted addresses and map links, so GeoToolbox seemed like a necessary addition. For the AI summary, we assumed we would use external Open AI API to generate it cause the setup is easy and it was the most familiar option to us at the time.

---

## The Exploration Log

_Not your conclusion, your actual process. Update this as you go, it doesn't need to be written in one sitting._

**What we browsed, and what surprised us:**

- We explored MapKit's `MKCoordinateRegion` and `MKMapView` to understand how to center the map on a live coordinate. The setup was straightforward.
- We looked for reverse geocoding and find that with `CLGeocoder`, we can implement that.
- We discovered `MKMapItem` can generate more details than `GeoToolBox` for pin location. So we decide to use only `MKMapItem` for our app.
- We discovered Apple's Foundation Models framework (`LanguageModelSession`) can generate good summary without addition of OpenAPI.

**What we actually built or tested in code:**

- A `LocationManager` class using `CLLocationManager` with `requestWhenInUseAuthorization()` that publishes the live coordinate via `@Published` for SwiftUI binding.
- An `MKCoordinateRegion` binding that re-centers the map whenever the user's coordinate updates.
- A reverse geocoding flow using `CLGeocoder.reverseGeocodeLocation()` that populates a detail card with a formatted address and a Maps link via `MKMapItem`.
- A `LanguageModelSession` prompt that receives the full JSON response from our `/api/analyze` endpoint and produces a single paragraph summarizing the property's risk profile.
- A PostGIS + Express.js backend (`/api/analyze`) returning raw property's risk data for any coordinate, The data contain like flood zones, air quality, temperature, elevation, population density, green spaces, road access, public facilities, internet connectivity, and crime statistics.

**What we discovered that we didn't expect:**

- `LanguageModelSession` (Foundation Models) runs fully on-device with no API key, no network call, and no usage cost. This was a significant departure from our starting assumption.
- Supabase free tier no longer exposes a direct PostgreSQL connection for new projects, routing all traffic through PgBouncer in transaction pooling mode. This caused abnormally high query planning times and overall API response times of 8–10 seconds.
- Migrating the database to Neon resolved the direct connection issue and brought API response time down to under 2 seconds.

---

## What We Tried and Dropped

_Name at least one real alternative you seriously considered, and explain why it got cut._

**We considered:**
Using `GeoToolBox` as the primary framework for surfacing location details at a tapped coordinate, such as place names, formatted addresses, Google Maps links, etc.

**We dropped it because:**
After exploring MapKit more thoroughly, we found that `MKMapItem` already provides a complete point description including place name, address, and a direct deep link to Apple Maps with no external dependency required.

---

**We considered:**
Keeping Supabase as the long term database host, since it was already in use during early development.

**We dropped it because:**
Supabase free tier removed direct PostgreSQL connections for new projects, forcing all traffic through PgBouncer in transaction pooling mode. This disabled prepared statement caching and inflated query planning time from the expected ~2ms to ~48ms per query, making the API too slow for our app loading. We migrated to NeonDB, which provides direct connections and full PostGIS support on the free tier.

---

## Real Limitations Hit

**Situation 1: Supabase pooler inflating PostGIS planning time**

The `/api/analyze` endpoint was consistently taking 8–10 seconds per request even with GIST spatial indexes on all geometry columns. Running `EXPLAIN ANALYZE` revealed query planning time of ~48ms per query, far above the normal 1–5ms, caused by PgBouncer's transaction pooling mode preventing statistics caching between connections.

How we worked around it:
We migrated the database from Supabase to Neon, which supports direct PostgreSQL connections on the free tier. Planning time dropped to normal levels and total API response time improved significantly.

---

**Situation 2: `LanguageModelSession` device and OS requirements**

Foundation Models' `LanguageModelSession` requires a device with Apple Silicon and iOS 26 or later. It is not available in the simulator and is unavailable on older devices.

How we worked around it:
We added a capability check before invoking the session and fall back to displaying a card if the model is unavailable on the user's device.

---

## The Revised Decision

**Final decision:**

- **CoreLocation**: live GPS coordinate capture via Location Manager, and address resolution via CLGeocoder (Reverse Geocoding)
- **MapKit**: map rendering and Coordinate Region centering
- **Foundation Models (`LanguageModelSession`)**: on-device AI summary generation from structured property risk data

**What changed since Section 1, and why:**

The only meaningful change was replacing the assumed external AI API with Apple's on-device `LanguageModelSession` cause we discovered that Foundation Models runs fully on-device with no API key or network dependency required, and its output quality was sufficient for summarizing structured JSON data into a readable property risk overview. The CoreLocation and MapKit pairing held exactly as assumed, and CLGeocoder (which was already part of CoreLocation) proved even easier to integrate than expected.

---

## App Track Addendum

### About the Frameworks

All three frameworks are genuinely necessary and work together in sequence. CoreLocation provides the coordinate and resolves the address, MapKit consumes that coordinate to render the map and display the surrounding area, Foundation Models consumes the environmental data retrieved using that same coordinate to generate the summary paragraph. Removing any one of them degrades the core use case: without CoreLocation there is no coordinate or address, without MapKit there is no spatial context, and without Foundation Models the user must interpret raw layer data themselves instead of getting a single readable overview.

The challenge response reflects this: _Create an app that utilizes Location Manager for location tracking, Reverse Geocoding for address resolution, Coordinate Regions for map navigation, and a Language Model Session to generate a concise, easy-to-read risk summary for any selected property._

### About Accessibility and Localization

We localized the app in two languages: `English` and `Bahasa Indonesia`. The target users for this app is Indonesian people who want buy property and tourism people who want rent property, so supporting both languages ensures the app is accessible to the full audience.

### About Privacy

The app requests a single permission: `NSLocationWhenInUseUsageDescription`, which allows location access only while the app is in the foreground. No location data is stored on-device or transmitted beyond the coordinate sent to our own backend API for spatial analysis. The AI summary is generated entirely on-device by Foundation Models and never leaves the device.

If the user denies location permission, the map defaults to a region centered on Bali and the "analyze current location" button is disabled. A card is shown to guide the user to enable location access in Settings. Everything else in the app still works normally.
