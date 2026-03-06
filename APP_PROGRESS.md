# Focus or Else Backend And App Status

Last updated: March 6, 2026

This document reflects the current implemented state of the app and backend.

## Overview

Focus or Else currently runs on:

- Flutter + Provider state management
- Firebase Authentication (Google + Email/Password)
- Cloud Firestore (users, usernames, pacts, friends, posts, chats)
- Firebase Storage (media upload)
- Environment-based Firebase configuration via `.env`

## Current App Modules

### Models (`lib/models/`)

- `user_model.dart`
- `pact_model.dart`
- `friend_model.dart`
- `post_model.dart`
- `post_comment_model.dart`
- `chat_message_model.dart`

### Services (`lib/services/`)

- `auth_service.dart`: auth flows and user bootstrap
- `firestore_service.dart`: all Firestore CRUD + streams + chat/unread logic
- `storage_service.dart`: profile and post media uploads
- `notification_service.dart`: notification-related plumbing

### Providers (`lib/providers/`)

- `auth_provider.dart`: auth/session/user profile state
- `pact_provider.dart`: active/completed/verification pact streams and actions
- `post_provider.dart`: post creation and feed/profile post state
- `theme_provider.dart`: app theme mode toggle and persistence behavior

### Screens (`lib/screens/`)

- Auth: `login_screen.dart`, `signup_screen.dart`, `forgot_password_screen.dart`
- Home: `dashboard_screen.dart`
- Pacts: `create_pact_screen.dart`
- Friends: `friends_tab_view.dart`, `friend_profile_screen.dart`
- Messages: `message_screen.dart`
- Profile: `profile_screen.dart`
- Settings: `settings_screen.dart`

## Implemented User Flows

### Authentication and Identity

- Google sign-in and email/password sign-in/up
- Username uniqueness enforced with dedicated `usernames` collection
- Google onboarding auto-generates unique username fallback
- Profile editing supports display name + username validation

### Dashboard and Navigation

- Bottom nav sections: Dashboard, Feed, Friends, Profile
- Create action flow for posts and pacts
- Theme mode toggle (light/dark) applied across major screens

### Friends and Social

- Friend search by username
- Send friend requests
- Incoming request management (accept/decline)
- In-app notifications popup for incoming friend requests
- Friend cards with pact status summary and review actions
- Friend profile screen with Message and Unfriend actions

### Messaging

- 1:1 chat screen per friend
- Message send and live stream
- Per-friend unread count badge on friend cards
- Mark-as-read flow when opening conversation

### Pacts

- Create pact flow with validation
- Verification method selection and friend verifier support
- Pact status tracking and review handling
- User stats and friend stats visual summaries

### Posts

- Create post with image upload
- Profile post grid and post detail interactions
- Likes and comments in Firestore subcollections

## Firestore Collections In Use

### `users/{userId}`

- Identity: `email`, `username`, `displayName`, `bio`, `profilePictureUrl`
- Stats: totals/streaks/rate
- Social links: `friendIds`
- Settings and timestamps

### `usernames/{username}`

- Reverse-lookup/claim record for unique usernames

### `pacts/{pactId}`

- Pact details, verification settings, status, evidence, timestamps

### `friends/{friendshipId}`

- `userId`, `friendId`, request `status`, `createdAt`, `acceptedAt`

### `posts/{postId}`

- Post metadata + counters
- Subcollections:
   - `likes/{userId}`
   - `comments/{commentId}`

### `chats/{chatId}`

- Chat metadata (`participants`, last message, unread counts)
- Subcollection:
   - `messages/{messageId}`

## Security Rules And Indexes

### Rules

- Source: `firestore.rules`
- Deployed via `firebase deploy --only firestore:rules --project focusorelse-5151a`
- Includes access control for:
   - signed-in user reads/writes
   - friend-based pact visibility
   - friends requests and updates
   - post likes/comments
   - chat/message participant checks

### Indexes

- Source: `firestore.indexes.json`
- Deployed via `firebase deploy --only firestore:indexes --project focusorelse-5151a`
- Includes composite indexes for `pacts` queries:
   - `userId + deadline`
   - `verifierId + deadline`
   - `status + userId + deadline`

## Core Runtime Configuration

- App entry: `lib/main.dart`
- Firebase init: `Firebase.initializeApp()` with `.env` support for options
- Dependencies: defined in `pubspec.yaml`

## Useful Commands

```bash
flutter pub get
flutter run
flutter analyze

firebase login
firebase deploy --only firestore:rules --project focusorelse-5151a
firebase deploy --only firestore:indexes --project focusorelse-5151a
```

## Current Status

- Backend is actively integrated with app features (not just scaffolded).
- Auth, profiles, friends, posts, pacts, notifications popup, and messaging are implemented.
- Firestore rules and indexes are versioned in repo and deployable.
