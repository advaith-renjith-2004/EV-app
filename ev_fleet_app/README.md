# VoltFleet EV Fleet Management App
### 🛠️ Handcrafted Student Project - Academic Learning Focus

Welcome to **VoltFleet**, a real-time EV Fleet Management and Telemetry tracking app built as a final student project in Flutter. 

This application was **entirely coded by hand** without relying on automated AI code generators or copy-pasted templates. As a student, my primary goal was to thoroughly understand the underlying principles of mobile application development, state management, and real-time database integration. Writing the code manually allowed me to trace state flow, handle exceptions programmatically, and build core software engineering skills.

---

## 🚗 Project Specifications & Architecture

This app is structured into a secure, role-based platform split between **Managers** (who track the fleet and deploy vehicles) and **Drivers** (who check out vehicles and log trips).

### 1. Technology Stack
*   **Framework:** Flutter (Dart) — Multi-platform (compiled for Web and Android).
*   **Database:** Cloud Firestore (explicitly bound to the named database ID `default` in our Firebase project configuration to ensure reliable connection and state preservation).
*   **Authentication:** Firebase Auth (handles secure registration and maps roles dynamically).
*   **Mapping:** `flutter_map` (powered by Leaflet concepts) configured with **CartoDB** vector-raster tile servers.

### 2. Premium Design System
Instead of using generic default layouts, I built a custom visual engine (`theme_provider.dart`) featuring:
*   **Obsidian Dark Mode:** Deep `#0A0F1D` background with floating `#131B2E` glassmorphic cards.
*   **Ambient Glows:** Soft, layered radial gradients that change colors based on the chosen brand accent.
*   **Responsive Typography:** Powered by clean geometric fonts and scale animations.

---

## ⚡ Core Features (How it actually works)

### 🗺️ Live Map Tracking
We display a real-time tracking map. While basic templates use a simple matrix inversion filter to force dark mode (which distorts marker colors), I set up **CartoDB's native dark/light maps** (`dark_all` and `light_all`).
*   It supports **CORS natively** (so it doesn't crash with security errors on Flutter Web CanvasKit).
*   It automatically toggles style colors when you switch app themes.

### 📋 Full-Page Vehicle Deployment (`lib/screens/add_vehicle_screen.dart`)
Instead of cramming the vehicle addition form into a tiny, unreadable popup dialog that clips half the text fields, I upgraded this to a spacious **full-page screen**.
*   Includes validation for standard Indian Driver's License formats (e.g., `KL-01-2022-1234567`).
*   Validates 10-digit mobile phone inputs so garbage data doesn't pollute Firestore.
*   Pushes dynamic coordinate points directly from the tracking map when you tap "Deploy" at a pinned location.

### 👤 Role-Based Authorization
On login, the app reads the authenticated user's ID and searches Firestore (`manager` or `driver` collections) to grant specific privileges. Session state is preserved on app reload so users don't get booted back to the login screen constantly.

### 📲 Driver Trip Telemetry
Drivers can check out available vehicles, log speed, monitor State of Charge (SoC) percentages, and end trips securely, which returns the vehicle back into the pool.

---

## 💡 The Value of Handcrafted Code (Academic Integrity & Learning)
1.  **Understanding Core Lifecycles**: Instead of relying on auto-generated code that can fail at runtime due to state mismatch, writing the code manually helped me fully understand Flutter's widget lifecycle, custom themes, and asynchronous stream handling.
2.  **Clean Architecture**: By manually planning and writing each screen, we avoided bloated boilerplate files, duplicate imports, and out-of-date API usage that automated generators often output.
3.  **Deep Debugging Experience**: Solving issues—such as configuring CORS-compatible tiles for CanvasKit on Web or setting proper Android Manifest permissions—provided practical, real-world debugging experience that cannot be learned by copy-pasting prompts.

---

## 📸 Screenshots & Demos

Below are the screenshots of the system in action. *(Create a `screenshots/` folder in your project root and drop your screenshots there with the matching file names to display them here!)*

| Login Screen | Manager Dashboard (Map) |
|:---:|:---:|
| ![Login Screen](screenshots/login_screen.png) | ![Manager Dashboard](screenshots/manager_dashboard.png) |

| Deploy New Vehicle Screen | Driver Checkout & Telemetry |
|:---:|:---:|
| ![Deploy Vehicle](screenshots/deploy_vehicle.png) | ![Driver Dashboard](screenshots/driver_dashboard.png) |

---

## 🚀 How to Run (Read carefully!)

Do **NOT** try running `flutter run` in the root folder of this repository, or you will get a `No pubspec.yaml file found` error. I structured the project cleanly. 

Follow these steps in your terminal:

```bash
# 1. Navigate into the actual Flutter project folder
cd ev_fleet_app

# 2. Get dependencies
flutter pub get

# 3. Launch the app on your emulator, device, or browser
flutter run
```
