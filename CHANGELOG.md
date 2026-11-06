# Changelog

All notable changes to G-spend are documented here.
Format: [Keep a Changelog](https://keepachangelog.com/). The CI release workflow
extracts the section matching the pushed tag (e.g. `v1.0.3` → `## [1.0.3]`) and
uses it as the GitHub Release body and the Play Store "what's new" notes.

## [Unreleased]

## [1.1.1] - 2026-11-06
### Fixed
- Pin release builds to Flutter 3.41.9 to match the tested SDK and resolve the intl dependency conflict.

## [1.1.0] - 2026-11-06
### Changed
- Refreshed the mobile interface with Geist typography, green accents, light/dark themes and persistent bottom navigation.
- Updated transaction, category, analysis, project and account screens.
- Configured release builds to use GitHub environment variables, including Google sign-in settings.

### Fixed
- Restored hidden transactions when filters are widened or reset.
- Preserved the active route when changing the app theme.

## [1.0.2]
### Changed
- Migrated the backend from Supabase + Drift + custom sync engine to **InstantDB** — realtime sync, offline-first local cache, and server-side permission rules.
- State management moved from BLoC to Cubit.

### Added
- Passwordless **magic-code** sign-in.
- Session persistence across restarts via a stored refresh token.

### Removed
- Email/password login, registration, and forgot-password screens.
