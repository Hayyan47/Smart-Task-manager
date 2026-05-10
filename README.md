# TaskMate - Smart Task Manager

This is a simple Flutter student project for managing tasks.

The code is intentionally kept basic and easy to understand. Most of the app is inside:

```text
lib/main.dart
```

## What the app can do

- Register a new user
- Login and logout
- Save user account data in Firebase
- Add tasks
- Edit tasks
- Delete tasks
- Mark tasks as completed
- Search tasks by title
- Filter tasks by All, Today, Upcoming, and Completed
- Store tasks in Firebase Firestore

## Main files

```text
lib/main.dart              Main app code
lib/firebase_options.dart  Firebase config file
pubspec.yaml              App packages/dependencies
FIREBASE_SETUP.md         Firebase setup instructions
```

## How to run

First install Flutter, then run:

```bash
flutter pub get
flutter run
```

## Firebase setup

Before login/signup works, connect your Firebase project:

```bash
flutterfire configure --project=your-firebase-project-id
```

Then enable these in Firebase Console:

1. Authentication → Email/Password
2. Cloud Firestore database

## Note for students

This version avoids advanced programming structure like many service/model/widget files. It uses simple classes, functions, if-statements, lists, and Firebase calls so it is easier to explain in class.
