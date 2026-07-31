# Task Management System

![Flutter](https://img.shields.io/badge/Flutter-02569B?logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-0175C2?logo=dart&logoColor=white)
![Firebase](https://img.shields.io/badge/Firebase-FFCA28?logo=firebase&logoColor=black)
![License](https://img.shields.io/badge/license-unspecified-lightgrey)

A Flutter task management application for organizing tasks, projects, teams, deadlines, and productivity workflows. The project combines a clean mobile interface with Firebase-backed authentication, real-time data, local persistence, and project-based task organization.

## Features

- Create, view, update, and delete tasks, organized into projects
- Assign tasks to team members and track deadlines/overdue items
- Search, filter, and sort task lists; view project progress and productivity insights
- Light and dark theme support with responsive, offline-friendly layouts
- Push notification support for reminders
- Firebase authentication, Firestore cloud storage, and SQLite local persistence with background sync

## Tech Stack

- Flutter
- Dart
- Firebase Auth
- Cloud Firestore
- Firebase Storage
- Provider
- SQLite
- Material Design 3

## Installation

```bash
git clone https://github.com/johnnnys3/task-management-system.git
cd task-management-system
flutter pub get
```

Firebase setup:

1. Create a Firebase project and enable Authentication and Firestore.
2. Add Android and/or iOS apps to the Firebase project.
3. Download the Firebase configuration files and place them in the required platform folders.
4. Run `flutterfire configure`.

## Usage

```bash
flutter run
```

```bash
flutter test              # run tests
flutter build apk --release   # build APK
flutter build web          # build web
```

## Project Structure

```text
lib/
├── authentication/      # Authentication services and screens
├── data/                # Database helpers and data sources
├── models/              # Data models
├── provider/            # State management
├── screens/             # App screens
├── service/             # Business logic and external services
└── widgets/             # Reusable UI components
```

## Contributing

Contributions are welcome. Fork the repository, create a feature branch, and open a pull request describing your changes.

## License

This project is available for educational and portfolio purposes.
