# TaskMate - Smart Task Manager

This is a simple Flutter student project for managing tasks.

The code now follows the simple Firebase flow requested for class:

```text
lib/
├── main.dart
├── signup_screen.dart
├── login_screen.dart
└── home_screen.dart
```

## What the app can do

- Login/signup screens formatted to match the submitted TaskMate design PDF
- Signup/Login now use purple top logo header with white form section like the screenshot
- Proper app bar, dashboard header, footer, and blue TaskMate theme
- Proposal-style menu button with drawer options: All Tasks, Today, High Priority, Study, Completed, and Logout
- Responsive wider layout for web/desktop while still working on phone
- Code kept basic, human-readable, and commented for class explanation
- Register a new user
- Login and logout
- Login/signup form validation using `Form` and `TextFormField`
- Add tasks
- Edit tasks
- Delete tasks
- Move tasks like Jira/Kanban from left to right: To Do → In Progress → In Review → Done
- Swipe task cards right/left to move between boards
- Search tasks by title
- Store tasks in Firebase Firestore

## Firebase Auth functions used

Only these main Firebase Auth functions are used:

```dart
createUserWithEmailAndPassword(email: email, password: password)
signInWithEmailAndPassword(email: email, password: password)
signOut()
```

## App flow

1. App opens → Login Screen
2. New user clicks Sign Up → Signup Screen → creates account → Home Screen
3. Existing user logs in → Home Screen
4. Home Screen logout button → back to Login Screen

## Main files

```text
lib/main.dart              Starts Firebase and opens LoginScreen
lib/login_screen.dart      Login screen
lib/signup_screen.dart     Signup screen
lib/home_screen.dart       Home screen with task board and logout
lib/firebase_options.dart  Firebase config file
pubspec.yaml              App packages/dependencies
FIREBASE_SETUP.md         Firebase setup instructions
LECTURE_ALIGNMENT.md      Explains how code follows lecture topics
```

## How to run

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
