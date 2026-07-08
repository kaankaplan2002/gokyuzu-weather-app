# GökYüzü — Premium Flutter Weather App

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-3.0%2B-02569B?style=for-the-badge&logo=flutter&logoColor=white"/>
  <img src="https://img.shields.io/badge/Dart-3.0%2B-0175C2?style=for-the-badge&logo=dart&logoColor=white"/>
  <img src="https://img.shields.io/badge/Platform-Android%20%7C%20iOS%20%7C%20Web%20%7C%20macOS%20%7C%20Windows%20%7C%20Linux-lightgrey?style=for-the-badge"/>
  <img src="https://img.shields.io/badge/API-Open--Meteo-green?style=for-the-badge"/>
</p>

> A premium, cross-platform Flutter weather application with a glassmorphic dashboard, dynamic aura effects, city search, and local favorites — powered by the Open-Meteo API with **no API key required**.

---

## ✨ Features

- **Zero-config API** — Uses Open-Meteo Geocoding & Forecast APIs. No API key or backend setup needed.
- **City Search** — Converts city names to latitude/longitude coordinates automatically.
- **Detailed Metrics** — Temperature, Feels Like, Humidity, Wind Speed, and Precipitation.
- **Local Storage** — Favorites and search history are persisted on-device via `shared_preferences` (JSON format).
- **Responsive Layout** — Side-by-side panel layout on large screens (Web/Tablet), vertical scrollable layout on mobile.
- **Dynamic Aura Effects** — Card backgrounds and shadow glows change dynamically based on current weather codes (clear, rainy, snowy, stormy, etc.).
- **Glassmorphism UI** — Frosted glass cards with blur effects and subtle gradients throughout.
- **Multi-platform** — Runs natively on Android, iOS, Web, macOS, Windows, and Linux.

---

## 📂 Project Structure

```
WEATHER APP/
├── README.md                   # Project documentation
├── .gitignore                  # Flutter standard gitignore
├── pubspec.yaml                # Flutter project config & dependencies (http, intl, shared_preferences)
│
└── lib/
    ├── main.dart               # App entry point & global Material 3 dark theme
    │
    ├── models/
    │   └── weather.dart        # Data models (WeatherData, FavoriteCity, SearchHistory)
    │
    ├── services/
    │   ├── api_service.dart    # Open-Meteo direct API calls
    │   └── storage_service.dart# SharedPreferences local storage management
    │
    └── screens/
        └── dashboard_screen.dart # Glassmorphic dashboard (Search, details, favorites, history)
```

---

## 🚀 Getting Started

### Prerequisites
- **Flutter SDK** 3.0.0 or higher installed on your machine
- An internet connection (for city search and weather data)

### Installation & Run

1. Clone the repository:
   ```bash
   git clone https://github.com/kaankaplan2002/gokyuzu-weather-app.git
   cd gokyuzu-weather-app
   ```

2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. Run on Chrome (Web):
   ```bash
   flutter run -d chrome
   ```

4. Run on a connected device or emulator:
   ```bash
   flutter run
   ```

---

## 📦 Production Build

| Platform | Command | Output |
|----------|---------|--------|
| Web | `flutter build web --release` | `build/web/` |
| Android APK | `flutter build apk --release` | `build/app/outputs/flutter-apk/` |
| iOS | `flutter build ios --release` | Xcode archive |
| macOS | `flutter build macos --release` | `build/macos/` |
| Windows | `flutter build windows --release` | `build/windows/` |

---

## 🛠️ External Services

| Service | Purpose | Docs |
|---------|---------|------|
| **Open-Meteo Geocoding API** | City name → coordinates | [geocoding-api.open-meteo.com](https://geocoding-api.open-meteo.com) |
| **Open-Meteo Forecast API** | Weather data & forecasts | [open-meteo.com](https://open-meteo.com) |
| **Google Fonts (Outfit)** | Premium typography | [fonts.google.com](https://fonts.google.com/specimen/Outfit) |

---

## 📦 Dependencies

```yaml
dependencies:
  http: ^1.x          # HTTP requests to Open-Meteo APIs
  intl: ^0.x          # Date & number formatting
  shared_preferences: ^2.x  # Local key-value storage
  google_fonts: ^6.x  # Outfit font family
```

---

## 📄 License

This project is open-source. Feel free to fork, modify, and build upon it.

---

<p align="center">Built with ❤️ using Flutter & Open-Meteo</p>
