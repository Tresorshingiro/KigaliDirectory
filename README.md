# Kigali City Services & Places Directory

A complete Flutter mobile application for discovering and managing city services and places in Kigali, Rwanda. Built with Firebase Authentication, Cloud Firestore, Google Maps integration, and Riverpod state management.

## Features

### Authentication
- **Email/Password Authentication** using Firebase Auth
- **Email Verification** - Users must verify their email before accessing the app
- **User Profile Management** - User profiles stored in Firestore with uid, email, displayName, and createdAt
- **Secure Session Management** - Automatic auth state handling with Riverpod

### Listing Management (CRUD Operations)
- **Create Listings** - Add new places and services with full details
- **Read Listings** - Real-time listing updates from Firestore
- **Update Listings** - Edit your own listings
- **Delete Listings** - Remove your listings with confirmation
- **Ownership Control** - Only listing creators can edit/delete their listings

### Directory Screen
- Browse all listings with a clean card-based UI
- **Search Functionality** - Filter listings by name, category, or address
- **Category Filters** - Quick filter chips for all categories
- **Categories Include**:
  - Hospital
  - Police Station
  - Library
  - Restaurant
  - Café
  - Park
  - Tourist Attraction

### Map View
- **Full-Screen Google Maps** integration
- Interactive markers for all listings
- Color-coded markers by category
- Info windows with listing name and category
- Auto-fit bounds to show all markers
- Tap info window to view details

### Listing Details
- Complete listing information display
- Embedded Google Map with marker
- **Get Directions** button - Opens Google Maps for turn-by-turn navigation
- Call functionality with phone dialer integration
- Clean, professional UI with dark theme

### My Listings Screen
- View all your created listings
- Floating action button to add new listings
- Edit and Delete buttons on each listing card
- Form validation for all fields
- Default Kigali coordinates (-1.9441, 30.0619)

### Settings Screen
- User profile display (email, display name)
- Email verification status badge
- **Location Notifications Toggle** (simulated with StateProvider)
- App version information
- Logout with confirmation dialog

## Tech Stack

- **Flutter & Dart** - Cross-platform mobile framework
- **Firebase Core** (^3.6.0) - Firebase initialization
- **Firebase Authentication** (^5.3.1) - User authentication
- **Cloud Firestore** (^5.4.4) - Real-time database
- **flutter_riverpod** (^2.5.1) - State management
- **google_maps_flutter** (^2.9.0) - Maps integration
- **geolocator** (^13.0.1) - Location services
- **url_launcher** (^6.3.0) - External URL/phone launching
- **uuid** (^4.5.1) - Unique ID generation

## Project Structure

```
lib/
├── main.dart                      # App entry point, auth wrapper, main shell
├── firebase_options.dart          # Firebase configuration (generated)
├── models/
│   ├── user_model.dart           # User data model
│   └── listing_model.dart        # Listing data model
├── services/
│   ├── auth_service.dart         # Firebase Auth operations
│   └── firestore_service.dart    # Firestore database operations
├── providers/
│   ├── auth_provider.dart        # Auth state management
│   └── listing_provider.dart     # Listing state management
├── screens/
│   ├── login_screen.dart         # Login UI
│   ├── signup_screen.dart        # Sign up UI
│   ├── directory_screen.dart     # Main directory with search/filters
│   ├── my_listings_screen.dart   # User's listings + create/edit form
│   ├── map_view_screen.dart      # Full-screen map view
│   ├── detail_screen.dart        # Listing details + embedded map
│   └── settings_screen.dart      # User settings and profile
└── widgets/
    └── listing_card.dart         # Reusable listing card widget
```

## Architecture & State Management

### Riverpod Providers
- **authServiceProvider** - AuthService instance
- **authStateProvider** - Stream of Firebase auth state
- **authNotifierProvider** - Auth operations (signUp, signIn, signOut)
- **firestoreServiceProvider** - FirestoreService instance
- **allListingsProvider** - Stream of all listings
- **userListingsProvider** - Stream of user's listings
- **filteredListingsProvider** - Computed provider with search/category filters
- **searchQueryProvider** - Search query state
- **selectedCategoryProvider** - Selected category filter
- **locationNotificationsProvider** - Notifications toggle state

### Service Layer Pattern
All database operations go through the service layer:
- **auth_service.dart** - All Firebase Auth operations
- **firestore_service.dart** - All Firestore operations
- **NO direct Firestore calls in UI** - Clean separation of concerns

## UI/UX Design

### Dark Theme
- **Background Color**: `#1A1A2E` (Dark navy blue)
- **Accent Color**: `#FFC107` (Amber/Yellow)
- **Card Background**: White with 10% opacity
- **Text**: White with varying opacity for hierarchy

### Navigation
- **Bottom Navigation Bar** with 4 tabs:
  1. Directory (list icon)
  2. My Listings (list_alt icon)
  3. Map (map icon)
  4. Settings (settings icon)

### Features
- Rounded corners (12px border radius)
- Card-based layouts
- Category-specific icons and colors
- Professional and polished appearance

## Firebase Configuration

### Firestore Collections

#### users/{uid}
```
{
  uid: String
  email: String
  displayName: String
  createdAt: Timestamp
}
```

#### listings/{id}
```
{
  id: String
  name: String
  category: String
  address: String
  contactNumber: String
  description: String
  latitude: double
  longitude: double
  createdBy: String (user UID)
  createdAt: Timestamp
}
```

### Security Rules (Recommended)
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && request.auth.uid == userId;
    }
    
    match /listings/{listingId} {
      allow read: if request.auth != null;
      allow create: if request.auth != null && request.resource.data.createdBy == request.auth.uid;
      allow update, delete: if request.auth != null && resource.data.createdBy == request.auth.uid;
    }
  }
}
```

## Setup & Installation

### Prerequisites
- Flutter SDK (^3.10.8)
- Firebase project with Authentication and Firestore enabled
- Google Maps API key for Android
- Android Studio / Xcode (for running on Android/iOS)

### Configuration
1. Firebase is already configured with `firebase_options.dart`
2. Google Maps API key is set in `AndroidManifest.xml`
3. minSdkVersion is set to 23
4. google-services.json is in `android/app/`

### Run the App
```bash
# Install dependencies
flutter pub get

# Run on connected device/emulator
flutter run

# Build release APK
flutter build apk --release
```

## Key Features Implementation

### Email Verification Flow
1. User signs up → Account created
2. Verification email sent automatically
3. User redirected to EmailVerificationScreen
4. Must verify email before accessing main app
5. Can resend verification email if needed

### Search & Filter
- **Real-time search** across name, category, and address
- **Category filter chips** at the top of directory
- **Computed provider** efficiently combines both filters
- Results update instantly as user types

### Listing Form
- All fields validated before submission
- Default Kigali coordinates provided
- Category dropdown with all 7 categories
- Separate create and edit modes
- Success/error feedback with SnackBars

### Map Integration
- Uses Google Maps Flutter plugin
- Custom marker colors per category
- Info window tap opens detail screen
- Auto-fit bounds to show all markers
- Supports zoom and pan gestures

### Get Directions
- URL launcher opens Google Maps app
- Format: `https://www.google.com/maps/dir/?api=1&destination={lat},{lng}`
- Falls back gracefully if Maps not installed

## Error Handling

- Firebase Auth exceptions mapped to user-friendly messages
- Firestore operations wrapped in try-catch
- Loading states shown during async operations
- Error states displayed with helpful messages
- Form validation prevents invalid data

## Best Practices

✅ **State Management**: Proper use of Riverpod providers  
✅ **Service Layer**: All database logic separated from UI  
✅ **Immutability**: Models use copyWith methods  
✅ **Error Handling**: Comprehensive error catching and user feedback  
✅ **Code Organization**: Clear folder structure by feature  
✅ **No Placeholders**: Fully implemented, production-ready code  
✅ **Material Design**: Following Flutter best practices  
✅ **Dark Theme**: Consistent color scheme throughout  

## Future Enhancements

- Add photo upload for listings
- Implement user ratings and reviews
- Add favorites/bookmarks functionality
- Push notifications for nearby places
- Filter by distance from current location
- Email/SMS verification for phone numbers
- Admin panel for moderation
- Multi-language support

## License

This project is created for educational purposes.

## Author

Built with ❤️ using Flutter and Firebase
