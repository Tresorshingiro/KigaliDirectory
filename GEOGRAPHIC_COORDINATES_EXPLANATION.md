# Geographic Coordinates Flow - Firestore to Google Maps

## Overview
This document explains how geographic coordinates (latitude and longitude) are retrieved from Cloud Firestore and passed to the Google Maps widget for display in the Kigali City Services app.

---

## 1. Data Storage in Firestore

### Listing Model Structure
Each listing in Firestore (`listings/{id}`) contains geographic coordinates:

```javascript
// Firestore Document Structure
{
  id: "xyz123",
  name: "King Faisal Hospital",
  category: "Hospital",
  address: "KG 544 St, Kigali",
  contactNumber: "+250788123456",
  description: "Major referral hospital in Kigali",
  latitude: -1.9576,    // ← Geographic coordinate (stored as double)
  longitude: 30.0939,   // ← Geographic coordinate (stored as double)
  createdBy: "user_uid_123",
  createdAt: Timestamp(2026-03-08)
}
```

**Key Points:**
- Coordinates are stored as **double** type numbers in Firestore
- Latitude: North-South position (-90 to +90 degrees)
- Longitude: East-West position (-180 to +180 degrees)
- Kigali coordinates are approximately: latitude -1.9441, longitude 30.0619

---

## 2. Data Retrieval from Firestore

### Step 1: Service Layer (`firestore_service.dart`)

The `FirestoreService` retrieves listing data from Firestore:

```dart
// firestore_service.dart (lines 19-30)
Stream<List<ListingModel>> getAllListingsStream() {
  return _firestore
      .collection('listings')                    // Connect to 'listings' collection
      .orderBy('createdAt', descending: true)   // Order by creation date
      .snapshots()                               // Real-time stream
      .map((snapshot) {                          // Transform snapshot data
    return snapshot.docs.map((doc) {
      return ListingModel.fromDocument(doc);    // Convert to ListingModel
    }).toList();
  });
}
```

**How it works:**
1. Connects to Firestore `listings` collection
2. Sets up real-time listener with `.snapshots()`
3. Receives QuerySnapshot whenever data changes
4. Transforms each DocumentSnapshot into ListingModel

---

### Step 2: Model Parsing (`listing_model.dart`)

The Firestore document is converted to a Dart object:

```dart
// listing_model.dart (lines 46-61)
factory ListingModel.fromMap(Map<String, dynamic> map) {
  return ListingModel(
    id: map['id'] as String,
    name: map['name'] as String,
    category: map['category'] as String,
    address: map['address'] as String,
    contactNumber: map['contactNumber'] as String,
    description: map['description'] as String,
    latitude: (map['latitude'] as num).toDouble(),    // ← Extract latitude
    longitude: (map['longitude'] as num).toDouble(),  // ← Extract longitude
    createdBy: map['createdBy'] as String,
    createdAt: (map['createdAt'] as Timestamp).toDate(),
  );
}

factory ListingModel.fromDocument(DocumentSnapshot doc) {
  final data = doc.data() as Map<String, dynamic>;
  return ListingModel.fromMap(data);                  // Use fromMap factory
}
```

**Coordinate Extraction:**
- `map['latitude']` retrieves the latitude value from Firestore
- Cast to `num` then convert to `double` for type safety
- Same process for longitude
- Now available as `listing.latitude` and `listing.longitude`

---

## 3. State Management with Riverpod

### Provider Setup (`listing_provider.dart`)

Coordinates flow through Riverpod providers:

```dart
// listing_provider.dart (lines 13-17)
final allListingsProvider = StreamProvider<List<ListingModel>>((ref) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService.getAllListingsStream();  // Stream of listings
});
```

**Data Flow:**
```
Firestore → FirestoreService → StreamProvider → UI Widgets
          (Real-time sync)      (State mgmt)    (Reactive updates)
```

---

## 4. Passing Coordinates to Map Widget

### Detail Screen Implementation (`detail_screen.dart`)

The coordinates are passed to GoogleMap widget in the Detail screen:

```dart
// detail_screen.dart (lines 82-109)
child: GoogleMap(
  // STEP 1: Set initial camera position using coordinates from Firestore
  initialCameraPosition: CameraPosition(
    target: LatLng(
      widget.listing.latitude,    // ← Latitude from Firestore
      widget.listing.longitude,   // ← Longitude from Firestore
    ),
    zoom: 15,  // Zoom level (15 = neighborhood level)
  ),
  
  // STEP 2: Create marker at the same coordinates
  markers: {
    Marker(
      markerId: MarkerId(widget.listing.id),  // Unique marker ID
      position: LatLng(
        widget.listing.latitude,     // ← Place marker at listing location
        widget.listing.longitude,
      ),
      infoWindow: InfoWindow(
        title: widget.listing.name,      // Show listing name
        snippet: widget.listing.category, // Show category
      ),
    ),
  },
  
  // Map controller for programmatic control
  onMapCreated: (controller) {
    _mapController = controller;
  },
  
  myLocationButtonEnabled: false,
  zoomControlsEnabled: false,
),
```

**Visual Representation:**
```
ListingModel (from Firestore)
    ↓
widget.listing.latitude  = -1.9576
widget.listing.longitude = 30.0939
    ↓
LatLng(latitude, longitude)  ← Google Maps coordinate format
    ↓
CameraPosition + Marker  ← Display on map
```

---

## 5. Navigation/Directions Feature

### Get Directions Button (`detail_screen.dart`)

When user taps "Get Directions", the app launches Google Maps:

```dart
// detail_screen.dart (lines 23-38)
Future<void> _launchDirections() async {
  // Construct Google Maps URL with coordinates from Firestore
  final url = Uri.parse(
    'https://www.google.com/maps/dir/?api=1&destination='
    '${widget.listing.latitude},${widget.listing.longitude}',
    //  ↑ Inject latitude         ↑ Inject longitude
  );

  // Launch external Google Maps app
  if (await canLaunchUrl(url)) {
    await launchUrl(url, mode: LaunchMode.externalApplication);
  } else {
    // Show error if Google Maps not available
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Could not launch directions')),
    );
  }
}
```

**URL Format:**
```
https://www.google.com/maps/dir/?api=1&destination=-1.9576,30.0939
                                                    ↑       ↑
                                                  lat     lng
```

This URL:
1. Opens Google Maps app (if installed)
2. Starts navigation mode (`/dir/`)
3. Sets destination to the listing's coordinates
4. Provides turn-by-turn directions from user's current location

---

## 6. Complete Data Flow Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                    FIRESTORE DATABASE                            │
│  Collection: listings/{id}                                       │
│  {                                                               │
│    latitude: -1.9576,  ← Stored as double                       │
│    longitude: 30.0939  ← Stored as double                       │
│  }                                                               │
└────────────────────┬────────────────────────────────────────────┘
                     │
                     ↓ Real-time stream (.snapshots())
              ┌──────────────────┐
              │ FirestoreService │
              │  getAllListings  │
              └────────┬─────────┘
                       │
                       ↓ DocumentSnapshot → ListingModel
                ┌──────────────────┐
                │  Listing Model   │
                │  fromDocument()  │
                │  - Parses data   │
                │  - Extracts lat  │
                │  - Extracts lng  │
                └────────┬─────────┘
                         │
                         ↓ Stream<List<ListingModel>>
                  ┌──────────────────┐
                  │ Riverpod Provider│
                  │ allListingsProvider
                  └────────┬─────────┘
                           │
                           ↓ Consumer watches provider
         ┌─────────────────────────────────────┐
         │                                      │
         ↓                                      ↓
  ┌─────────────┐                      ┌───────────────┐
  │ Directory   │                      │ Detail Screen │
  │ Screen      │ → Tap listing →     │               │
  │ (List view) │                      │ GoogleMap     │
  └─────────────┘                      │ widget        │
                                       └───────┬───────┘
                                               │
                                               ↓
                                    ┌──────────────────────┐
                                    │ GoogleMap displays:   │
                                    │ - Camera at (lat,lng) │
                                    │ - Marker at (lat,lng) │
                                    └──────────┬────────────┘
                                               │
                                               ↓ User taps "Get Directions"
                                    ┌──────────────────────┐
                                    │ url_launcher opens:   │
                                    │ Google Maps with      │
                                    │ destination=(lat,lng) │
                                    └───────────────────────┘
```

---

## 7. Key Technical Points

### Type Conversions
```dart
// Firestore stores as number (could be int or double)
latitude: -1.9576  (stored as number in Firestore)

// Parse safely with type cast
(map['latitude'] as num).toDouble()  // Ensures it's double

// Use in Google Maps
LatLng(latitude, longitude)  // Requires double values
```

### Real-time Updates
- **StreamProvider** ensures UI updates automatically when Firestore data changes
- If coordinates are updated in Firestore, the map updates immediately
- No manual refresh needed

### Navigation URL Format
```dart
// Google Maps Directions API URL structure:
'https://www.google.com/maps/dir/'  // Base URL for directions
'?api=1'                             // Use Google Maps API v1
'&destination=LAT,LNG'               // Destination coordinates
```

Alternative format using `geo:` URI:
```dart
'geo:0,0?q=${latitude},${longitude}(${Uri.encodeComponent(name)})'
```

---

## 8. Error Handling

### Coordinate Validation
The app ensures valid coordinates:

```dart
// In form validation (my_listings_screen.dart)
validator: (value) {
  if (value == null || value.isEmpty) {
    return 'Required';
  }
  if (double.tryParse(value) == null) {
    return 'Invalid';  // Ensures numeric value
  }
  return null;
}
```

### Launch URL Handling
```dart
if (await canLaunchUrl(url)) {
  await launchUrl(url);
} else {
  // Show error if Google Maps not installed
  ScaffoldMessenger.of(context).showSnackBar(...);
}
```

---

## 9. Testing the Flow

### To verify coordinates are working:

1. **Check Firestore Console:**
   - Open Firebase Console → Firestore Database
   - View a listing document
   - Verify `latitude` and `longitude` fields exist

2. **Check App Display:**
   - Open a listing in Detail Screen
   - Verify embedded map shows correct location
   - Verify marker appears at the right place

3. **Test Navigation:**
   - Tap "Get Directions" button
   - Google Maps should open
   - Destination should match the listing location

4. **Debug Coordinates:**
```dart
// Add debug print in detail_screen.dart
print('Listing coordinates: ${widget.listing.latitude}, ${widget.listing.longitude}');
```

---

## 10. Summary

**Complete Flow:**
1. User creates listing with coordinates → Saved to Firestore
2. FirestoreService streams data → Converts to ListingModel
3. Riverpod provider manages state → UI receives data
4. Detail screen receives listing → Extracts coordinates
5. GoogleMap widget displays → Camera + Marker at coordinates
6. User taps directions → Launches Google Maps with coordinates

**Key Files:**
- `listing_model.dart` - Coordinate data structure and parsing
- `firestore_service.dart` - Database retrieval
- `listing_provider.dart` - State management
- `detail_screen.dart` - Map display and navigation
- `AndroidManifest.xml` - Required permissions and queries

**Technologies:**
- Cloud Firestore - Geographic data storage
- google_maps_flutter - Map visualization
- url_launcher - External navigation
- flutter_riverpod - Reactive state management

---

This architecture ensures efficient, real-time geographic coordinate handling from database to visual display with proper error handling and type safety throughout the data flow.
