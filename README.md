# Focus or Else (FoE)

Focus or Else is a social accountability app built with Flutter and Firebase.
Users create pacts, stay accountable with friends, share progress, and message friends directly.

## Features

### Authentication and Identity

- Google sign-in and email/password sign-in/up
- Username + display name identity model
- Username uniqueness enforcement in Firestore (`usernames` collection)

### Pacts

- Create pacts with category, deadline, verification method, and consequences
- Friend verification and pact review flow
- Active/expired pact tracking and stats

### Friends

- Search users by username and send friend requests
- Incoming friend request section with accept/decline
- Friend cards with pact status labels and quick actions
- Friend profile view with Message and Unfriend actions

### Messaging

- 1:1 chat between friends
- Real-time message stream
- Per-friend unread badge count on messaging icon

### Profile and Posts

- Editable user profile (display name, username, bio, avatar)
- Post creation with image upload
- Profile post grid and stats charts

### UI/UX

- Bottom navigation (Dashboard, Feed, Friends, Profile)
- In-app notifications popup (anchored below bell icon)
- Light and dark theme support across major screens

## Prerequisites

- Flutter SDK `3.9.2+`
- Dart SDK `3.9.2+`
- Firebase project
- Android Studio / Xcode
- Node.js + npm (for Firebase CLI)

## Setup

### 1. Clone and install

```bash
git clone https://github.com/kevj-github/focusorelse.git
cd focusorelse
flutter pub get
```

### 2. Configure environment

```bash
cp .env.example .env
```

Populate `.env` with your Firebase values.
See [SECURITY.md](SECURITY.md) for details.

### 3. Add Firebase app config files

- `android/app/google-services.json`
- `ios/Runner/GoogleService-Info.plist`

### 4. Deploy Firestore rules and indexes

This project includes Firestore config files:

- `firestore.rules`
- `firestore.indexes.json`

Deploy them before testing friend stats/chat:

```bash
npm install -g firebase-tools
firebase login
firebase deploy --only firestore:rules --project focusorelse-5151a
firebase deploy --only firestore:indexes --project focusorelse-5151a
```

### 5. Run app

```bash
flutter run
```

## Project Structure

```text
lib/
   main.dart
   firebase_options.dart
   models/
      user_model.dart
      pact_model.dart
      friend_model.dart
      post_model.dart
      post_comment_model.dart
      chat_message_model.dart
   providers/
      auth_provider.dart
      pact_provider.dart
      post_provider.dart
      theme_provider.dart
   screens/
      auth/
      create_pact/
      friends/
      home/
      messages/
      profile/
      settings/
   services/
      auth_service.dart
      firestore_service.dart
      storage_service.dart
      notification_service.dart
```

## Tech Stack

- Flutter + Material 3
- Provider
- Firebase Auth
- Cloud Firestore
- Firebase Storage
- Firebase Messaging

## Common Troubleshooting

### `PERMISSION_DENIED` on Firestore queries

- Ensure latest `firestore.rules` are deployed.

### `FAILED_PRECONDITION: The query requires an index`

- Ensure `firestore.indexes.json` is deployed.
- Wait for index build to complete in Firebase Console.

### App feels stuck on emulator

- This can happen with emulator rendering/jank.
- Try full restart (`flutter run`), emulator cold boot, or physical device.

### Google sign-in fails on another device

- Confirm local config exists on that machine:
   - `.env` with Firebase values
   - `android/app/google-services.json`
- Ensure Firebase Android app registration matches `applicationId` from `android/app/build.gradle.kts`.
- Add SHA-1 and SHA-256 fingerprints for the signing key used by that build/device in Firebase Console.
- If using release builds, do not sign with debug key. Configure a release keystore and register that keystore fingerprints in Firebase.
- Rebuild app after config updates.

## Documentation

- [Backend Setup and Current Status](BACKEND_SETUP_COMPLETE.md)
- [Security Notes](SECURITY.md)
- [Flutter Implementation Plan](iter1/Flutter_Implementation_Plan.md)

## Security Note

Never commit:

- `.env`
- `android/app/google-services.json`
- `ios/Runner/GoogleService-Info.plist`
