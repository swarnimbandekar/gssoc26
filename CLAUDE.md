# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Flutter mobile app for the GSSoC (GirlScript Summer of Code) contribution leaderboard with glassmorphic UI design.

## Development Commands

```bash
flutter pub get        # Install dependencies
flutter run            # Run app in debug mode
flutter analyze        # Run static analysis / linting
flutter test           # Run all tests
flutter test test/widget_test.dart  # Run a specific test file
flutter build apk --release  # Build Android release APK
flutter build ios --release  # Build iOS release
flutter build web          # Build for web
```

## Architecture

Clean architecture with Riverpod for state management:

- `lib/core/` - Constants, themes (glassmorphic theme with app_colors.dart), utilities (debouncer)
- `lib/data/` - Data models (`contributor.dart`), repositories, and services
- `lib/providers/` - Riverpod state providers (`leaderboard_provider.dart`)
- `lib/presentation/` - UI layer: screens (home, profile, projects, search) and reusable widgets

## Key Dependencies

- **flutter_riverpod** - State management
- **go_router** - Declarative routing/navigation
- **cached_network_image** - Image caching and loading states
- **shimmer** - Loading placeholder animations
- **lottie** - JSON-based animations (GitHub bubble animation in assets)
- **http** - API requests for leaderboard data
- **shared_preferences** - Local data persistence

## Data Flow

1. `LeaderboardRepository` fetches data from GSSoC API
2. `leaderboard_provider.dart` manages state with Riverpod
3. Screens consume providers via `ref.watch()` / `ref.read()`
4. Models (`Contributor`) define the data structure

## UI Patterns

- Glassmorphic containers and cards throughout the UI
- Shimmer loading placeholders for async content
- Animated counters for stats display
- Pagination bar for leaderboard navigation
- Bottom navigation with 4 tabs (Home, Search, Projects, Profile)

## Asset Notes

- `Github bubble Lottie JSON animation.json` - Animated GitHub logo used on profile screens
- `gssoclogo.png` - GSSoC branding asset
