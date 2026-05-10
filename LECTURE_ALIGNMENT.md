# How this project follows the Mobile Application Development lectures

This is a short summary written in my own words after reviewing the lecture notes. The app code is kept simple so it can be explained easily in class.

## Lecture concepts used in the app

- **Flutter framework:** The app is built in Flutter with one codebase for mobile/web.
- **Dart basics:** The code uses variables, strings, booleans, lists, maps, functions, classes, and if/else logic.
- **Project structure:** Main code is in `lib/main.dart`, with dependencies in `pubspec.yaml`.
- **Widgets:** The UI uses `MaterialApp`, `Scaffold`, `AppBar`, `Text`, `Icon`, `Card`, `ListView`, `Column`, `Row`, `DropdownButtonFormField`, `ElevatedButton`, and `FloatingActionButton`.
- **StatelessWidget and StatefulWidget:** Login and home screens use state to update forms, search text, loading, and task board changes.
- **Layout widgets:** The interface uses `Column`, `Row`, `Padding`, `Card`, and `ListView` for simple layout.
- **Forms and validation:** Login/register uses `Form`, `GlobalKey<FormState>`, and `TextFormField` validators.
- **Controllers:** Text input uses `TextEditingController`.
- **Local storage:** `SharedPreferences` is used for the “Remember my email” option.
- **Firebase:** Firebase Authentication is used for login/signup and Cloud Firestore is used to save tasks.

## Extra project feature

The task screen now works like a simple Jira/Kanban board:

1. To Do
2. In Progress
3. In Review
4. Done

Each task has a dropdown to move it from one status to another.
