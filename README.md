# Task Management System

![Flutter](https://img.shields.io/badge/Flutter-02569B?logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-0175C2?logo=dart&logoColor=white)
![Firebase](https://img.shields.io/badge/Firebase-FFCA28?logo=firebase&logoColor=black)

A Flutter task management application for organizing tasks, projects, teams, deadlines, and productivity workflows. The project combines a clean mobile interface with Firebase-backed authentication, real-time data, local persistence, and project-based task organization.

## Overview

This app is designed to help users manage personal and team productivity from one place. Users can create tasks, organize them into projects, assign responsibilities, track progress, and receive reminders for important deadlines.

## Features

### Core Functionality

- Create, view, update, and delete tasks
- Organize tasks into projects
- Assign tasks to team members
- Track deadlines and overdue tasks
- Search, filter, and sort task lists
- View project progress and productivity insights

### User Experience

- Modern Flutter interface
- Material Design-inspired layout
- Light and dark theme support
- Responsive layouts for different screen sizes
- Offline-friendly local storage
- Push notification support for reminders

### Backend and Data

- Firebase authentication
- Firestore for cloud data storage
- SQLite for local persistence
- Background synchronization between local and remote data
- Role-based team access structure

## Tech Stack

- Flutter
- Dart
- Firebase Auth
- Cloud Firestore
- Firebase Storage
- Provider
- SQLite
- Material Design 3

## Getting Started

### Prerequisites

- Flutter SDK 3.0 or newer
- Dart SDK 3.0 or newer
- Android Studio or VS Code with Flutter extensions
- Firebase project

### Installation

```bash
git clone https://github.com/johnnnys3/task-management-system.git
cd task-management-system
flutter pub get
```

### Firebase Configuration

1. Create a Firebase project.
2. Enable Authentication and Firestore.
3. Add Android and/or iOS apps to the Firebase project.
4. Download the Firebase configuration files.
5. Place the files in the required platform folders.
6. Run:

```bash
flutterfire configure
```

### Run the App

```bash
flutter run
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

## Development

### Run Tests

```bash
flutter test
```

### Build APK

```bash
flutter build apk --release
```

### Build Web

```bash
flutter build web
```

## Portfolio Value

This project demonstrates mobile app development with Flutter, state management, Firebase integration, local persistence, authentication, task workflows, and responsive UI design.

## Future Improvements

- Calendar integration
- Advanced analytics dashboard
- Team invitation flow
- File attachments for tasks
- Notification scheduling improvements
- More complete test coverage

## License

This project is available for educational and portfolio purposes.

## Contact

**John Kessie**  
GitHub: [johnnnys3](https://github.com/johnnnys3)  
Email: johnkessie04@gmail.com
