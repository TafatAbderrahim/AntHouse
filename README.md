<<<<<<< HEAD
# AntHouse
BMS WareHouse management for MobAi Hackathon
=======
# BMS Warehouse Viz

Flutter application for warehouse operations visualization and management.

## Features

- Multi-role experience: Admin, Supervisor, Employee
- Warehouse map visualization (floors, zones, occupancy, heatmap)
- Task and operations flows (picking, storage, receipt, delivery)
- Audit logs and overrides monitoring
- AI analytics and validation screens

## Tech Stack

- Flutter (Dart)
- Android, Linux, Web targets

## Project Structure

- `lib/models` data models and generators
- `lib/screens` app screens and role shells
- `lib/widgets` reusable UI widgets and painters
- `lib/services` supporting services (pathfinding, etc.)
- `assets/images` static assets

## Prerequisites

- Flutter SDK installed and available in PATH
- Android SDK (for APK builds)
- JDK 21 for Android build compatibility

## Setup

```bash
flutter pub get
```

## Run

Linux desktop:

```bash
flutter run -d linux
```

Android device/emulator:

```bash
flutter run -d android
```

## Build APK (Release)

This project should be built with Java 21.

```bash
export JAVA_HOME=/usr/lib/jvm/java-21-openjdk
export PATH="$JAVA_HOME/bin:$PATH"
flutter build apk --release
```

Output APK:

`build/app/outputs/flutter-apk/app-release.apk`

## Notes

- If Android components are missing, Flutter/Gradle may auto-install Build Tools, NDK, or CMake.
- If you hit Java version errors (for example with Java 25), switch to Java 21 before building.

## Useful Commands

```bash
flutter clean
flutter pub get
flutter analyze
```
>>>>>>> bab3b73 (Initial commit: BMS Warehouse Viz)
