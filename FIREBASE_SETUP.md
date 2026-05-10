# Firebase Setup for TaskMate

Follow these steps before running the app on Android/iOS.

## 1. Create Firebase project

1. Open <https://console.firebase.google.com/>
2. Create a project, for example: `taskmate-flutter`
3. Enable **Authentication → Sign-in method → Email/Password**
4. Create **Cloud Firestore** in test mode first, then replace rules with the rules below

## 2. Install CLIs

```bash
dart pub global activate flutterfire_cli
npm install -g firebase-tools
firebase login
```

If `flutterfire` is not found after activation, add Dart pub cache to PATH:

```bash
export PATH="$PATH:$HOME/.pub-cache/bin"
```

## 3. Generate Firebase options

From inside this project folder:

```bash
flutterfire configure --project=<your-firebase-project-id>
```

This replaces `lib/firebase_options.dart` with real Firebase app config and creates platform config files.

## 4. Firestore security rules

Use these rules so each user can only access their own tasks/profile:

```txt
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }

    match /tasks/{taskId} {
      allow create: if request.auth != null
        && request.resource.data.userId == request.auth.uid;

      allow read, update, delete: if request.auth != null
        && resource.data.userId == request.auth.uid;
    }
  }
}
```

## 5. Android reminder permission

For Android 13+, notification permission is required. If reminders do not appear, grant notification permission from app settings. For exact alarms, Android may also require exact alarm permission depending on the device.

## 6. Run

```bash
flutter pub get
flutter run
```
