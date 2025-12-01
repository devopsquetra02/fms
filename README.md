# E-FMS Mobile App

A production Flutter application for **E-FMS (Electronic Fleet Management System)**.

This mobile app is designed for drivers and field operations to:
- View and manage daily **jobs/tasks**.
- See the list of **vehicles** and their details.
- View a **map**, vehicle positions, and geofenced zones.
- Perform **real-time vehicle tracking** through Traxroot integration.

## Key Features

- **Authentication & Session Management**  
  Login using credentials provided by the backend, store tokens securely using `SecureStorage` and `SharedPreferences`, and automatically validate the session through `RootGate` (`AuthController`).

- **Dashboard & Map (Home)**  
  The Home tab shows the dashboard and map:
  - Fetches objects/vehicles, icons, statuses, and geozones from Traxroot.
  - Highlights vehicles that are currently moving or idle.
  - Shows detailed information when a vehicle marker is tapped.

- **Job Management**  
  The jobs module provides:
  - **All Job**, **Ongoing**, and **History** tabs powered by backend data.
  - Actions to **start**, **finish**, **reschedule**, and **cancel** a job.
  - Job detail pages and job history views.

- **Vehicle List & Tracking**  
  The vehicles module provides:
  - A vehicle list with search and group-based filters.
  - Icon/type information for each vehicle.
  - Navigation to vehicle tracking and vehicle status summary pages.

- **Notifications & Home Widget (Android)**  
  Uses `firebase_messaging`, `flutter_local_notifications`, and `home_widget` to:
  - Receive push notifications from the backend (e.g. job updates or alerts).
  - Expose a home screen widget (Android) that can deep-link into specific parts of the app.

## Technology Stack

- **Flutter** (Dart SDK `^3.9.0`).
- **State Management & Routing**: [GetX](https://pub.dev/packages/get).
- **Firebase**: `firebase_core`, `firebase_messaging` (push notifications).
- **Maps & Location**: `flutter_map`, `google_maps_flutter`, `latlong2`.
- **Local Storage**: `flutter_secure_storage`, `shared_preferences`.
- **HTTP Client**: `http`.
- **UI/UX Utilities**: `cached_network_image`, `flutter_local_notifications`, `home_widget`, `url_launcher`, `image_picker`, and more.

See `pubspec.yaml` for the complete dependency list.

## Project Structure (Overview)

Some important folders/files:

- **`lib/main.dart`**  
  App entry point. Initializes Firebase, configures the theme, and uses `RootGate` to decide whether to show `NavBar` (main app) or `LoginPage`.

- **`lib/page/auth/`**  
  Login screen(s) and `AuthController` for login, logout, session checking, and preloading key data after authentication.

- **`lib/page/home/`**  
  - `home_page.dart` (HomeTab, FullMapPage) for the dashboard and map.
  - `home_controller.dart` for managing map data, markers, geozones, and job summaries.

- **`lib/page/vehicles/`**  
  - `vehicles_page.dart` for the vehicle list, search, and filters.
  - `vehicles_controller.dart` for retrieving vehicle data, icons, and groups.

- **`lib/page/jobs/`**  
  - `jobs_page.dart` for the All/Ongoing/History tabbed interface.
  - `jobs_controller.dart` for job data management and actions (start/finish/reschedule/cancel).

- **`lib/data/`**  
  Data sources (`datasource`) and models used to communicate with the internal backend and Traxroot.

- **`lib/core/`**  
  Constants, configuration (`variables.dart`), services (e.g. `TraxrootCredentialsManager`, `HomeWidgetService`), shared UI components, theming (`app_theme.dart`), and other utilities.

- **`lib/nav_bar.dart`**  
  Main bottom navigation managing the **Home**, **Vehicles**, and **Jobs** tabs.

## Requirements

- Flutter SDK (compatible with Dart `^3.9.0`).
- Android Studio or VS Code with Flutter plugins.
- Xcode (for building iOS, if needed).
- Access to the E-FMS backend and valid user credentials.

## Running the Project Locally

1. **Clone the repository**
   ```bash
   git clone <this-repo-url>
   cd fms
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure Firebase**
   - Ensure `android/app/google-services.json` is present and correctly configured for your Firebase project.
   - For iOS, make sure `ios/Runner/GoogleService-Info.plist` is added and `Runner` is configured according to the official Firebase docs.

4. **Configure Backend & App Variables**
   - Check `lib/core/constants/variables.dart` (and related config files) for:
     - Backend API base URL.
     - Any other required keys/constants.
   - Adjust values according to your environment (dev/staging/production).

5. **Run the app**
   ```bash
   flutter run
   ```

## Building for Release

### Android

```bash
flutter build apk --release
```

Or for App Bundle:

```bash
flutter build appbundle --release
```

### iOS

```bash
flutter build ios --release
```

Follow the official Flutter documentation for code signing and publishing to the Play Store / App Store.

## Development Notes

- Run `flutter pub outdated` and `flutter pub upgrade --major-versions` periodically to keep dependencies up to date (after validating with your backend).
- GetX structure (controller + view) is separated per module (`auth`, `home`, `vehicles`, `jobs`) to make maintenance and feature development easier.


