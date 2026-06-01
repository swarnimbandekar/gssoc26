# GSSoC 26

A Flutter mobile application for tracking and displaying the GSSoC (GirlScript Summer of Code) contribution leaderboard.

## Features



- Real-time leaderboard rankings
- Contributor profiles with detailed statistics
- Search functionality
- Project tracking
- Beautiful glassmorphic UI design

## Screenshots

*(Add screenshots here)*

## Getting Started

### Prerequisites

- Flutter SDK (3.x or higher)
- Dart SDK (3.x or higher)
- Android Studio / Xcode for mobile development

### Installation

1. Clone the repository:
```bash
git clone https://github.com/yourusername/gssoc-leaderboard.git
cd gssoc-leaderboard
```

2. Install dependencies:
```bash
flutter pub get
```

3. Run the app:
```bash
flutter run
```

## Building

### Android
```bash
flutter build apk --release
```
APK will be in `build/app/outputs/flutter-apk/app-release.apk`

### iOS
```bash
flutter build ios --release
```
Build will be in `build/ios/iphoneos/`

### Web
```bash
flutter build web
```
Build will be in `build/web/`

## Architecture

The app follows a clean architecture pattern with Riverpod for state management:

- `lib/core/` - Constants, themes, utilities
- `lib/data/` - Models and repositories
- `lib/providers/` - State management
- `lib/presentation/` - Screens and widgets

## Contributing

Contributions are welcome! Please read [CONTRIBUTING.md](CONTRIBUTING.md) for details.

## License

This project is open source and available under the [MIT License](LICENSE).
