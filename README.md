# 💰 G-spend - Smart Expense Tracker

A local-first expense tracking app built with Flutter and InstantDB.

[![GitHub release](https://img.shields.io/github/v/release/tsiresymila1/expense-mobile)](https://github.com/tsiresymila1/expense-mobile/releases/tag/v1.0.0)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter)](https://flutter.dev)
[![InstantDB](https://img.shields.io/badge/InstantDB-Self--hosted-6C47FF)](https://www.instantdb.com)

## 📱 Screenshots
[Add your app screenshots here]

## ✨ Features

- 💰 **Smart Expense Tracking** - Track income and expenses with custom categories
- 📊 **Visual Analytics** - Beautiful charts and spending insights
- 🔄 **Offline-First** - Works without internet, syncs automatically
- 🎨 **Modern UI** - Material Design 3 with dark mode
- 🌍 **Multi-Language** - English & French support
- 💱 **Multi-Currency** - Support for any currency
- 🔐 **Secure** - InstantDB magic-code and Google OAuth authentication

## 🚀 Download

**Latest Release: v1.0.0**

- [Download APK](https://github.com/tsiresymila1/expense-mobile/releases/download/v1.0.0/G-Expense.apk)
- [View All Releases](https://github.com/tsiresymila1/expense-mobile/releases)

## 🛠️ Tech Stack

- **Framework**: Flutter 3.x
- **Backend**: Self-hosted InstantDB (local cache, authentication, realtime sync)
- **State Management**: BLoC + Hydrated BLoC
- **Local Database**: Drift (SQLite)
- **Architecture**: Clean Architecture

## 📦 Installation

### From Release
1. Download the latest APK from [Releases](https://github.com/tsiresymila1/expense-mobile/releases)
2. Install on your Android device
3. Create an account and start tracking!

### Build from Source
```bash
# Clone the repository
git clone [https://github.com/tsiresymila1/expense-mobile.git](https://github.com/tsiresymila1/expense-mobile.git)
cd expense-mobile

# Install dependencies
flutter pub get

# Run build_runner
dart run build_runner build --delete-conflicting-outputs

# Configure the self-hosted backend (same values for dev and prod)
cp .env.dev.example .env.dev
cp .env.prod.example .env.prod

# Run the app
flutter run --flavor dev -t lib/main_dev.dart
```

## Google OAuth setup

Google sign-in uses InstantDB's OAuth PKCE flow. No Google client secret is
stored in the Flutter application.

1. Create a Google Web OAuth client and configure its consent screen.
2. In the InstantDB dashboard, open **Auth**, add the Google client using the
   name `google`, and enter the Google client ID and secret.
3. Add InstantDB's Google callback URL to the Google client's authorized
   redirect URIs.
4. Add these non-secret values to `.env.dev` and `.env.prod`:

```dotenv
GOOGLE_OAUTH_CLIENT_NAME=google
GOOGLE_OAUTH_REDIRECT_URI=ts.mila.expense://login-callback
```

The Google button remains hidden when these values are absent, so an
unconfigured build cannot expose a broken login method.
