# TaskMate

TaskMate is a Flutter smart task manager built from the project proposal/design. It includes Firebase email/password authentication, Firestore task storage, task filtering/search, CRUD operations, completion tracking, priority/category fields, and local deadline reminders.

## Features

- Register, login, logout, password validation
- Firebase Auth for secure accounts
- Firestore database with per-user tasks
- Add, edit, delete, and complete tasks
- Task fields: title, description, due date/time, priority, category
- Filters: All, Today, Upcoming, Completed
- Search tasks by title
- Local notification reminder 1 hour before deadline
- Clean UI matching the submitted login/register design direction

## Project status

The app code is ready, but Flutter is not installed on the machine where this was generated, so it was not compiled here. To run it locally, install Flutter, configure Firebase, then run the commands below.

## Getting started

```bash
cd taskmate_flutter
flutter create . --platforms=android,ios
flutter pub get
flutterfire configure --project=<your-firebase-project-id>
flutter run
```

`flutter create .` adds the Android/iOS platform folders around the existing `lib/` and `pubspec.yaml` files.

## Firebase setup

See [`FIREBASE_SETUP.md`](FIREBASE_SETUP.md).

## Suggested GitHub repository name

`taskmate-flutter`

After you review the code, create a public GitHub repo and push this folder there.
