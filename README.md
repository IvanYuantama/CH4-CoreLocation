## Present Your Team

| Name                   | Role                |
| ---------------------- | ------------------- |
| Andhika Pangestu       | Tech                |
| Benedict Kenjiro Lehot | Tech                |
| Ivan Yuantama Pradipta | Tech                |
| Ryan Safa Tjendana     | Design              |
| William Gozali         | Tech, Domain Expert |

---

## Starting Assumption

_What did you assume, before any real exploration (start of investigation phase)? Be honest, including if your assumption is basically a guess. Write it and move on._

We think we'll end up using:

- MapKit for rendering the map
- CoreLocation for capturing GPS coordinates
- GeoToolbox for giving location details like place names, Maps links, and another information at a tapped coordinate
- WeatherKit for capturing additional variables like temperature, humidity, etc
- FoundationModels to make a summary based on provided data.

Because:
We try to make plus and minus for every framework like CoreHaptics, CoreMotion, CoreLocation and Nearby Interaction. We decide to use CoreLocation for our core framework because it give more plus better than another framework, and also we have 1 domain expert to do geography. And then, we decide to use MapKit for displaying map, and GeoToolBox for giving information about pin location like Maps Link, Name of the place, etc. We also use WeatherKit to get realtime variable data so we can have more additional data. We also use FoundationModels to generate a summary to be shown before each detailed data.

---

## The Exploration Log

_Not your conclusion, your actual process. Update this as you go, it doesn't need to be written in one sitting._

**What we browsed, and what surprised us:**

- We explored MapKit to understand how to center the map on a live coordinate and how to displaying map using MapKit.
- We looked for reverse geocoding and find that with CoreLocation `CLGeocoder`, we can implement that.
- MapKit can generate more details than `GeoToolBox` for pin location. So we decide to use only MapKit `MKMapItem` for our app.
- If we want to use WeatherKit, we need to activate that features on an Apple Developer account.

**What we actually built or tested in code:**

- A CoreLocation realtime GPS coordinate using iphone
- A CoreLocation reverse geocoding for pinning a point location
- A WeatherKit that fetches current temperature, humidity, etc, for the selected coordinate
- A LanguageModelSession class from FoundationModels to make a summary data
- A PostGIS + Express.js backend to process and give geojson data

**What we discovered that we didn't expect:**

- Supabase free tier no longer exposes a direct PostgreSQL connection for new projects, it will use pooling mode that make API response times more longer like 8–10 seconds.
- Migrating the database to NeonDB resolved the direct connection issue and brought API response time down to under 2 seconds.
- The FoundationModels still not provide model for Bahasa Indonesia.

---

## What We Tried and Dropped

_Name at least one real alternative you seriously considered, and explain why it got cut._

**We considered:**
Using GeoToolBox for giving location details at a tapped coordinate, like place names, formatted addresses, Maps links, etc.

**We dropped it because:**
After exploring MapKit, we found that `MKMapItem` already provides a complete point description including place name, address, and a direct deep link to Apple Maps with no external dependency required.

**We considered:**
Not using Supabase Free Trial

**We dropped it because:**
Supabase free tier removed direct PostgreSQL connections for new projects our API request too slow for geojson data. We migrated to NeonDB, which provides direct connections and full PostGIS support on the free tier.

**We considered:**
Using FoundationModels to make a summary.

**We dropped it because:**
We tried the FoundationModels, but it only works when our device (Iphone 17) is using English as it's general system languange. From what we found, FoundationModels has several language it currently support, but Indonesia wasn't on the list. We did tried with several other language on the list as our general system language, but the model also didn't work. For as long as we've tested, the FoundationModels only work when the general system language is English. We then thought to only use this model when the device language is English and replace it with a template when other language is used, but then we come to a sense like "Why not just use a template for every device language and not use an AI model to make a summary?"

---

## Real Limitations Hit

**Situation 1: Supabase pooler inflating PostGIS planning time**

The test endpoint was consistently taking 8–10 seconds per request even with GIST spatial indexes on all geometry columns.

How we worked around it:
We migrated the database from Supabase to Neon, which supports direct PostgreSQL connections on the free tier. Planning time dropped to normal levels and total API response time improved significantly.

**Situation 2: Bahasa is not supported by Language Model Session**

Language Model Session can't work if we use Bahasa

How we worked around it:
We will make summary template for both language.

---

## The Revised Decision

**Final decision:**

- **CoreLocation**: live GPS coordinate capture via Location Manager, and address resolution via CLGeocoder (Reverse Geocoding)
- **MapKit**: map rendering and Coordinate Region centering
- **WeatherKit**: for giving additional variabel data to make our app more detail.

**What changed since Section 1, and why:**

We not use GeoToolBox anymore because MapKit already give more detail data for pinning location better than GeoToolBox. We not use Foundation Models (Language Model Session) because it not work for Bahasa, so we decide to use template for both language.

---

## App Track Addendum

### About the Frameworks

All three frameworks are genuinely necessary and work together in sequence. CoreLocation provides the coordinate and realtime GPS location, MapKit consumes that coordinate to render the map and display the surrounding area, WeatherKit consumes that same coordinate to fetch realtime data (temperature, humidity, etc) that enrich the property overview with live conditions rather than static data alone. Removing any one of them degrades the core use case: without CoreLocation there is no coordinate, without MapKit there is no map displaying, and without WeatherKit the overview doesnt have real environmental data.

The challenge response reflects this: _Create an app that utilizes Location Manager for location tracking, Reverse Geocoding for address resolution, Coordinate Regions for map navigation, and WeatherService to to fetch and present environmental conditions data for any selected property._

### About Accessibility and Localization

We localized the app in two languages, English and Bahasa Indonesia. The target users for this app is Indonesian people who want buy property and tourism people who want rent property, so supporting both languages ensures the app is accessible to the full audience.

### About Privacy

The app requests a single permission Location Access, which allows GPS location run only while the app is in the foreground. Location data is sent to our own backend API for spatial analysis.

If the user denies location permission, the map will display but can't analyze the place that the user now there. A card is shown to guide the user to enable location access in Settings. Everything else in the app still works normally.
