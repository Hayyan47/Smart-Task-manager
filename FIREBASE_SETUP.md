# Firebase Setup for TaskMate

Follow these steps before running the app.

## 1. Create Firebase project

1. Open <https://console.firebase.google.com/>
2. Create a project, for example: `smart-task-manager`
3. Enable **Authentication → Sign-in method → Email/Password**
4. Create **Cloud Firestore Database**

## 2. Install Firebase tools

```bash
dart pub global activate flutterfire_cli
npm install -g firebase-tools
firebase login
```

If `flutterfire` is not found, run:

```bash
export PATH="$PATH:$HOME/.pub-cache/bin"
```

## 3. Connect Firebase with Flutter

Run this command inside the project folder:

```bash
flutterfire configure --project=your-firebase-project-id
```

This will update `lib/firebase_options.dart` with your real Firebase project settings.

## 4. Firestore security rules

Use these rules in Firebase Console → Firestore → Rules:

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

## 5. Run the app

```bash
flutter pub get
flutter run
```
