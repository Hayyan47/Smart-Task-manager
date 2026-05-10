# How this project follows the Mobile Application Development lectures

This is a short summary written in my own words after reviewing the lecture notes. The app code is kept simple so it can be explained easily in class.

## Lecture concepts used in the app

- **Flutter framework:** The app is built in Flutter with one codebase for mobile/web.
- **Dart basics:** The code uses variables, strings, booleans, lists, maps, functions, classes, and if/else logic.
- **Project structure:** The project now follows the requested simple file structure:

```text
lib/
├── main.dart
├── signup_screen.dart
├── login_screen.dart
└── home_screen.dart
```

- **Widgets:** The UI uses `MaterialApp`, `Scaffold`, `AppBar`, `Text`, `Icon`, `Card`, `ListView`, `Column`, `Row`, `DropdownButtonFormField`, `ElevatedButton`, and `FloatingActionButton`.
- **StatelessWidget and StatefulWidget:** Login, signup, and home screens use state to update forms, loading, search text, and task board changes.
- **Layout widgets:** The interface uses `Column`, `Row`, `Padding`, `Card`, and `ListView` for simple layout.
- **Forms and validation:** Login/signup use `Form`, `GlobalKey<FormState>`, and `TextFormField` validators.
- **Controllers:** Text input uses `TextEditingController`.
- **Firebase Auth:** The auth flow uses only the important Firebase functions:
  - Signup: `createUserWithEmailAndPassword(email, password)`
  - Login: `signInWithEmailAndPassword(email, password)`
  - Logout: `signOut()`
- **Cloud Firestore:** Firestore is used to save and load tasks for each logged-in user.

## App flow

1. App opens on the Login Screen.
2. New user clicks Sign Up, creates an account, then goes to Home.
3. Existing user logs in and goes to Home.
4. Home Screen has a logout button, which returns to Login.

## Extra project feature

The task screen works like a simple Jira/Kanban board, arranged left to right like Jira:

1. To Do
2. In Progress
3. In Review
4. Done

Each task has a dropdown to move it from one status to another. You can also long press and drag a task card into another board column.
