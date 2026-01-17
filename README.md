# 💰 G-spend - Smart Expense Tracker

A beautiful, offline-first expense tracking app built with Flutter and Supabase.

[![GitHub release](https://img.shields.io/github/v/release/tsiresymila1/expense-mobile)](https://github.com/tsiresymila1/expense-mobile/releases/tag/v1.0.0)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter)](https://flutter.dev)
[![Supabase](https://img.shields.io/badge/Supabase-Backend-3ECF8E?logo=supabase)](https://supabase.com)

## 📱 Screenshots
[Add your app screenshots here]

## ✨ Features

- 💰 **Smart Expense Tracking** - Track income and expenses with custom categories
- 📊 **Visual Analytics** - Beautiful charts and spending insights
- 🔄 **Offline-First** - Works without internet, syncs automatically
- 🎨 **Modern UI** - Material Design 3 with dark mode
- 🌍 **Multi-Language** - English & French support
- 💱 **Multi-Currency** - Support for any currency
- 🔐 **Secure** - Supabase authentication and encryption

## 🚀 Download

**Latest Release: v1.0.0**

- [Download APK](https://github.com/tsiresymila1/expense-mobile/releases/download/v1.0.0/G-Expense.apk)
- [View All Releases](https://github.com/tsiresymila1/expense-mobile/releases)

## 🛠️ Tech Stack

- **Framework**: Flutter 3.x
- **Backend**: Supabase (PostgreSQL, Auth, Realtime)
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

# Run the app
flutter run --flavor prod